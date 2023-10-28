import React, { ReactNode, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../../base/html-translate';
import { FabInput } from '../../base/fab-input';
import { Loader } from '../../base/loader';
import SettingAPI from '../../../api/setting';
import PagseguroAPI from '../../../api/pagseguro';
import Switch from 'react-switch';

interface PagseguroKeysFormProps {
  onValidKeys: (token: string, email: string, isProduction: boolean, urlToRedirect: string, urlToNotify: string) => void,
  onInvalidKeys: () => void,
}

/**
 * Form to set PagSeguro Token
 */
const PagseguroKeysForm: React.FC<PagseguroKeysFormProps> = ({ onValidKeys, onInvalidKeys }) => {
  const { t } = useTranslation('admin');

  // used to prevent promises from resolving if the component was unmounted
  const mounted = useRef(false);

  // PagSeguro environment
  const [isProduction, setIsProduction] = useState<boolean>(false);
  // Url for redirect User after checkout
  const [urlToRedirect, setUrlToRedirect] = useState<string>('');
  // Url endpoint to webhook
  const [urlToNotify, setUrlToNotify] = useState<string>('');
  // PagSeguro token
  const [token, setToken] = useState<string>('');
  // Style class for add-on token
  const [tokenAddOnClassName, setTokenAddOnClassName] = useState<string>('');
  // Icon for token input
  const [tokenAddOn, setTokenAddOn] = useState<ReactNode>(null);
  // PagSeguro email
  const [email, setEmail] = useState<string>('');
  // Style class for add-on email
  const [emailAddOnClassName, setEmailAddOnClassName] = useState<string>('');
  // Icon for email input
  const [emailAddOn, setEmailAddOn] = useState<ReactNode>(null);
  /**
   * When the component loads for the first time:
   * - mark it as mounted
   * - initialize the keys with the values fetched from the API (if any)
   */
  useEffect(() => {
    mounted.current = true;

    SettingAPI.query(['pagseguro_token', 'pagseguro_email', 'pagseguro_production', 'pagseguro_url_notify', 'pagseguro_url_redirect']).then(pagseguroKeys => {
      setToken(pagseguroKeys.get('pagseguro_token'));
      setEmail(pagseguroKeys.get('pagseguro_email'));
      setIsProduction(pagseguroKeys.get('pagseguro_production') === 'true');
      setUrlToNotify(pagseguroKeys.get('pagseguro_url_notify'));
      setUrlToRedirect(pagseguroKeys.get('pagseguro_url_redirect'));
    }).catch(error => console.error(error));

    // when the component unmounts, mark it as unmounted
    return () => {
      mounted.current = false;
    };
  }, []);

  /**
   * When the style class for the public and private key are updated, check if they indicate valid keys.
   * If both are valid, run the 'onValidKeys' callback
   */
  useEffect(() => {
    const validClassName = 'key-valid';
    if (tokenAddOnClassName === validClassName && emailAddOnClassName === validClassName) {
      onValidKeys(token, email, isProduction, urlToRedirect, urlToNotify);
    } else {
      onInvalidKeys();
    }
  }, [tokenAddOnClassName, emailAddOnClassName]);

  /**
   * Validate email input
   */
  const validateEmail = (email: string) => {
    setEmailAddOnClassName('');

    if (/^[a-zA-Z0-9]+[\w.-]*@[\w.-]*\.[\w-]{2,}$/.test(email)) {
      setEmail(email);
      setEmailAddOn(<i className="fa fa-check" />);
      setEmailAddOnClassName('key-valid');
    } else {
      setEmailAddOn(<i className="fa fa-times" />);
      setEmailAddOnClassName('key-invalid');
    }
  };

  /**
   * Send a test call to PagSeguro API to validate token
   */
  const testToken = (key: string) => {
    setTokenAddOnClassName('');

    if (key.length !== 32) {
      setTokenAddOn(<i className="fa fa-times" />);
      setTokenAddOnClassName('key-invalid');
      return;
    }
    if (email === '') return;
    PagseguroAPI.testToken(key, email).then(() => {
      if (!mounted.current) return;

      setToken(key);
      setTokenAddOn(<i className="fa fa-check" />);
      setTokenAddOnClassName('key-valid');
    }, reason => {
      if (!mounted.current) return;

      if (reason.response.status === 401) {
        setTokenAddOn(<i className="fa fa-times" />);
        setTokenAddOnClassName('key-invalid');
      }
    });
  };

  return (
    <div className="pagseguro-keys-form">
      <div className="pagseguro-keys-info">
        <HtmlTranslate trKey="app.admin.invoices.pagseguro_keys_form.pagseguro_keys_info_html" />
      </div>
      <form name="pagseguroKeysForm">
      <div className="pagseguro-secret-input">
          <label htmlFor="pagseguro_production">{ t('app.admin.invoices.pagseguro_keys_form.is_production') }</label>
          <Switch id="pagseguro_production"
            checked={isProduction}
            className="switch"
            onChange={(val) => setIsProduction(val)}
          />
      </div>
      <div className="pagseguro-secret-input">
          <label htmlFor="pagseguro_url_to_redirect">{ t('app.admin.invoices.pagseguro_keys_form.url_redirect') } *</label>
          <FabInput id="pagseguro_url_redirect"
            defaultValue={urlToRedirect}
            onChange={(val: string) => setUrlToRedirect(val)}
            addOn={() => null}
            addOnClassName={''}
            debounce={50}
            type="url"
            required/>
      </div>
      <div className="pagseguro-secret-input">
          <label htmlFor="pagseguro_url_to_notify">{ t('app.admin.invoices.pagseguro_keys_form.url_notify') } *</label>
          <FabInput id="pagseguro_url_notify"
            defaultValue={urlToNotify}
            onChange={(val: string) => setUrlToNotify(val)}
            addOn={() => null}
            addOnClassName={''}
            debounce={50}
            type="url"
            required/>
      </div>
      <div className="pagseguro-secret-input">
          <label htmlFor="pagseguro_email">{ t('app.admin.invoices.pagseguro_keys_form.email') } *</label>
          <FabInput id="pagseguro_email"
            icon={<i className="fa fa-envelope" />}
            defaultValue={email}
            onChange={validateEmail}
            addOn={emailAddOn}
            addOnClassName={emailAddOnClassName}
            debounce={50}
            type="email"
            required/>
        </div>
        <div className="pagseguro-secret-input">
          <label htmlFor="pagseguro_token">{ t('app.admin.invoices.pagseguro_keys_form.token') } *</label>
          <FabInput id="pagseguro_token"
            icon={<i className="fa fa-key" />}
            defaultValue={token}
            onChange={testToken}
            addOn={tokenAddOn}
            addOnClassName={tokenAddOnClassName}
            debounce={200}
            required/>
        </div>
      </form>
    </div>
  );
};

const PagseguroKeysFormWrapper: React.FC<PagseguroKeysFormProps> = (props) => {
  return (
    <Loader>
      <PagseguroKeysForm {...props} />
    </Loader>
  );
};

export { PagseguroKeysFormWrapper as PagseguroKeysForm };
