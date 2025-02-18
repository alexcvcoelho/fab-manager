import { FunctionComponent, ReactNode } from 'react';
import * as React from 'react';
import { GatewayFormProps, AbstractPaymentModal } from '../abstract-payment-modal';
import { ShoppingCart } from '../../../models/payment';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { User } from '../../../models/user';
import { Invoice } from '../../../models/invoice';

import securitySite from '../../../../../images/security-site.png';
import getnet from '../../../../../images/getnet.png';
import { GetnetForm } from './getnet-form';
import { Order } from '../../../models/order';

interface GetnetModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule|Order) => void,
  onError: (message: string) => void,
  cart: ShoppingCart,
  order?: Order,
  currentUser: User,
  schedule?: PaymentSchedule,
  customer: User
}

/**
 * This component enables the user to input his card data or process payments, using the PayZen gateway.
 * Supports Strong-Customer Authentication (SCA).
 *
 * This component should not be called directly. Prefer using <CardPaymentModal> which can handle the configuration
 *  of a different payment gateway.
 */
export const GetnetModal: React.FC<GetnetModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, cart, currentUser, schedule, customer, order }) => {
  /**
   * Return the logos, shown in the modal footer.
   */
  const logoFooter = (): ReactNode => {
    return (
      <div className="getnet-modal-icons">
        <img src={getnet} alt='Getnet' />
        <img src={securitySite} alt="powered by Firjan" />
      </div>
    );
  };

  /**
   * Integrates the PayzenForm into the parent PaymentModal
   */
  const renderForm: FunctionComponent<GatewayFormProps> = ({ onSubmit, onSuccess, onError, operator, className, formId, cart, customer, paymentSchedule, children, order }) => {
    return (
      <GetnetForm onSubmit={onSubmit}
        onSuccess={onSuccess}
        onError={onError}
        customer={customer}
        operator={operator}
        formId={formId}
        cart={cart}
        order={order}
        className={className}
        paymentSchedule={paymentSchedule}>
        {children}
      </GetnetForm>
    );
  };

  return (
    <AbstractPaymentModal isOpen={isOpen}
      toggleModal={toggleModal}
      logoFooter={logoFooter()}
      formId="getnet-form"
      formClassName="getnet-form"
      className="getnet-modal"
      currentUser={currentUser}
      cart={cart}
      order={order}
      customer={customer}
      afterSuccess={afterSuccess}
      onError={onError}
      schedule={schedule}
      GatewayForm={renderForm} />
  );
};
