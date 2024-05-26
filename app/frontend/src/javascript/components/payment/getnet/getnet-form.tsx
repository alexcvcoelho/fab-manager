import { FormEvent, FunctionComponent, useEffect, useRef, useState } from 'react';
import * as React from 'react';
import KRGlue from '@lyracom/embedded-form-glue';
import { GatewayFormProps } from '../abstract-payment-modal';
import SettingAPI from '../../../api/setting';
import PayzenAPI from '../../../api/payzen';
import {
  CreateTokenResponse,
  KryptonClient,
  KryptonError, PaymentTransaction,
  ProcessPaymentAnswer
} from '../../../models/getnet';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { Invoice } from '../../../models/invoice';
import CheckoutAPI from '../../../api/checkout';
import { Order } from '../../../models/order';
import { FabInput } from '../../base/fab-input';

// we use these two additional parameters to update the card, if provided
interface PayzenFormProps extends GatewayFormProps {
  updateCard?: boolean,
}

/**
 * A form component to collect the credit card details and to create the payment method on Stripe.
 * The form validation button must be created elsewhere, using the attribute form={formId}.
 */
export const GetnetForm: React.FC<PayzenFormProps> = ({ onSubmit, onSuccess, onError, children, className, paymentSchedule, updateCard = false, cart, customer, formId, order }) => {
  const PayZenKR = useRef<KryptonClient>(null);
  const [loadingClass, setLoadingClass] = useState<'hidden' | 'loader' | 'loader-overlay'>('hidden');

  useEffect(() => {
    SettingAPI.query(['payzen_endpoint', 'payzen_public_key']).then(settings => {
      createToken().then(formToken => {
        // Load the remote library
        KRGlue.loadLibrary(settings.get('payzen_endpoint'), settings.get('payzen_public_key'))
          .then(({ KR }) =>
            KR.setFormConfig({
              formToken: formToken.formToken
            })
          )
          .then(({ KR }) => KR.addForm('#payzenPaymentForm'))
          .then(({ KR, result }) => KR.showForm(result.formId))
          .then(({ KR }) => KR.onFormReady(handleFormReady))
          .then(({ KR }) => KR.onFormCreated(handleFormCreated))
          .then(({ KR }) => { PayZenKR.current = KR; });
      }).catch(error => onError(error));
    });
  }, [cart, paymentSchedule, customer, order]);

  /**
   * Ask the API to create the form token.
   * Depending on the current transaction (schedule or not), a PayZen Token or Payment may be created.
   */
  const createToken = async (): Promise<CreateTokenResponse> => {
    if (updateCard) {
      return await PayzenAPI.updateToken(paymentSchedule?.id);
    } else if (paymentSchedule) {
      return await PayzenAPI.chargeCreateToken(cart, customer);
    } else if (order) {
      const res = await CheckoutAPI.payment(order);
      return res.payment as CreateTokenResponse;
    } else {
      return await PayzenAPI.chargeCreatePayment(cart, customer);
    }
  };

  /**
   * Callback triggered on PayZen successful payments
   * @see https://docs.lyra.com/fr/rest/V4.0/javascript/features/reference.html#kronsubmit
   */
  const onPaid = (event: ProcessPaymentAnswer): boolean => {
    PayzenAPI.checkHash(event.hashAlgorithm, event.hashKey, event.hash, event.rawClientAnswer).then(async (hash) => {
      if (hash.validity) {
        if (updateCard) return onSuccess(null);

        const transaction = event.clientAnswer.transactions[0];
        if (event.clientAnswer.orderStatus === 'PAID') {
          confirmPayment(event, transaction).then((confirmation) => {
            PayZenKR.current.removeForms().then(() => {
              onSuccess(confirmation);
            });
          }).catch(e => onError(e));
        } else {
          const error = `${transaction?.errorMessage}. ${transaction?.detailedErrorMessage || ''}`;
          onError(error || event.clientAnswer.orderStatus);
        }
      }
    });
    return true;
  };

  /**
   * Confirm the payment, depending on the current type of payment (single shot or recurring)
   */
  const confirmPayment = async (event: ProcessPaymentAnswer, transaction: PaymentTransaction): Promise<Invoice | PaymentSchedule | Order> => {
    if (paymentSchedule) {
      return await PayzenAPI.confirmPaymentSchedule(event.clientAnswer.orderDetails.orderId, transaction.uuid, cart);
    } else if (order) {
      const res = await CheckoutAPI.confirmPayment(order, event.clientAnswer.orderDetails.orderId);
      return res.order;
    } else {
      return await PayzenAPI.confirm(event.clientAnswer.orderDetails.orderId, cart);
    }
  };

  /**
   * Callback triggered when the PayZen form was entirely loaded and displayed
   * @see https://docs.lyra.com/fr/rest/V4.0/javascript/features/reference.html#%C3%89v%C3%A9nements
   */
  const handleFormReady = () => {
    setLoadingClass('hidden');
  };

  /**
   * Callback triggered when the PayZen form has started to show up but is not entirely loaded
   * @see https://docs.lyra.com/fr/rest/V4.0/javascript/features/reference.html#%C3%89v%C3%A9nements
   */
  const handleFormCreated = () => {
    setLoadingClass('loader-overlay');
  };

  /**
   * Callback triggered when the PayZen payment was refused
   * @see https://docs.lyra.com/fr/rest/V4.0/javascript/features/reference.html#kronerror
   */
  const handleError = (answer: KryptonError) => {
    const message = `${answer.errorMessage}. ${answer.detailedErrorMessage ? answer.detailedErrorMessage : ''}`;
    onError(message);
  };

  /**
   * Handle the submission of the form.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    event.stopPropagation();
    onSubmit();

    try {
      const { result } = await PayZenKR.current.validateForm();
      if (result === null) {
        if (!order) {
          await PayzenAPI.checkCart(cart, customer);
        }
        await PayZenKR.current.onSubmit(onPaid);
        await PayZenKR.current.onError(handleError);
        await PayZenKR.current.submit();
      }
    } catch (err) {
      // catch api errors
      onError(err);
    }
  };

  /**
   * Return a loader
   */
  const Loader: FunctionComponent = () => {
    return (
      <div className={`fa-3x ${loadingClass}`}>
        <i className="fas fa-circle-notch fa-spin" />
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit} id={formId} className={`getnet-form ${className || ''}`}>
      <Loader />
      <div className="getnet-container">
        <div className="getnet-card-input">
          <label htmlFor="getnet_card">Número do cartão</label>
          <FabInput id="getnet_card"
            icon={<i className="fa fa-credit-card" />}
            type="text"
            required />
        </div>
        <div className="getnet-card-name-input">
          <label htmlFor="getnet_card_name">Nome do cartão</label>
          <FabInput id="getnet_card_name"
            icon={<i className="fa fa-user" />}
            type="text"
            required />
        </div>
        <div className='getnet-line-cvv-expiration'>
          <div className="getnet-card-expiration-input">
            <label htmlFor="getnet_card_expiration">Data de validade</label>
            <FabInput id="getnet_card_expiration"
              icon={<i className="fa fa-calendar" />}
              type="text"
              placeholder='DD/MM'
              required />
          </div>
          <div className="getnet-card-cvv-input">
            <label htmlFor="getnet_card_cvv">CVV</label>
            <FabInput id="getnet_card_cvv"
              icon={<i className="fa fa-key" />}
              type="text"
              required />
          </div>
        </div>
      </div>
      {children}
    </form>
  );
};
