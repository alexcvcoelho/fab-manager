import { ReactNode, useEffect, useState } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { enableMapSet } from 'immer';
import { useImmer } from 'use-immer';
import { HtmlTranslate } from '../../base/html-translate';
import { FabInput } from '../../base/fab-input';
import { Loader } from '../../base/loader';
import { SettingName } from '../../../models/setting';
import SettingAPI from '../../../api/setting';
import GetnetAPI from '../../../api/getnet';

enableMapSet();

interface GetnetKeysFormProps {
  onValidKeys: (getnetSettings: Map<SettingName, string>) => void,
  onInvalidKeys: () => void,
}

// all settings related to Getnet that are requested by this form
const getnetSettings: Array<SettingName> = ['getnet_seller_id', 'getnet_client_id', 'getnet_client_secret', 'getnet_endpoint'];
// settings related to the Getnet REST API (server side)
const restApiSettings: Array<SettingName> = ['getnet_seller_id', 'getnet_client_id', 'getnet_client_secret', 'getnet_endpoint'];

// Prevent multiples call to the getnet keys validation endpoint.
// this cannot be handled by a React state because of their asynchronous nature
let pendingKeysValidation = false;

/**
 * Form to set the Getnet's username, password and public key
 */
const GetnetKeysForm: React.FC<GetnetKeysFormProps> = ({ onValidKeys, onInvalidKeys }) => {
  const { t } = useTranslation('admin');

  // values of the Getnet settings
  const [settings, updateSettings] = useImmer<Map<SettingName, string>>(new Map(getnetSettings.map(name => [name, ''])));
  // Icon of the fieldset for the Getnet's keys concerning the REST API. Used to display if the key is valid.
  const [keysAddOn, setKeysAddOn] = useState<ReactNode>(null);
  // Style class for the add-on icon, for the REST API
  const [keysAddOnClassName, setKeysAddOnClassName] = useState<'key-invalid' | 'key-valid' | ''>('');

  /**
   * When the component loads for the first time, initialize the keys with the values fetched from the API (if any)
   */
  useEffect(() => {
    SettingAPI.query(getnetSettings).then(getnetKeys => {
      updateSettings(new Map(getnetKeys));
    }).catch(error => console.error(error));
  }, []);

  /**
   * When the style class for the public key, and the REST API are updated, check if they indicate valid keys.
   * If both are valid, run the 'onValidKeys' callback, else run 'onInvalidKeys'
   */
  useEffect(() => {
    const validClassName = 'key-valid';
    if (keysAddOnClassName === validClassName) {
      onValidKeys(settings);
    } else {
      onInvalidKeys();
    }
  }, [keysAddOnClassName, settings]);

  useEffect(() => {
    testRestApi();
  }, [settings]);

  /**
   * Send a test call to the payZen REST API to check if the inputted settings key are valid.
   * Depending on the test result, assign an add-on icon and a style to notify the user.
   */
  const testRestApi = () => {
    const valid: boolean = restApiSettings.map(s => !!settings.get(s))
      .reduce((acc, val) => acc && val, true);

    if (valid && !pendingKeysValidation) {
      pendingKeysValidation = true;
      GetnetAPI.sdkTest(
        settings.get('getnet_endpoint'),
        settings.get('getnet_seller_id'),
        settings.get('getnet_client_id'),
        settings.get('getnet_client_secret')
      ).then(result => {
        pendingKeysValidation = false;

        if (result.success) {
          setKeysAddOn(<i className="fa fa-check" />);
          setKeysAddOnClassName('key-valid');
        } else {
          setKeysAddOn(<i className="fa fa-times" />);
          setKeysAddOnClassName('key-invalid');
        }
      }, () => {
        pendingKeysValidation = false;

        setKeysAddOn(<i className="fa fa-times" />);
        setKeysAddOnClassName('key-invalid');
      });
    }
    if (!valid) {
      setKeysAddOn(<i className="fa fa-times" />);
      setKeysAddOnClassName('key-invalid');
    }
  };

  /**
   * Assign the inputted key to the given settings
   */
  const setApiKey = (setting: typeof restApiSettings[number]) => {
    return (key: string) => {
      updateSettings(draft => draft.set(setting, key));
    };
  };

  return (
    <div className="getnet-keys-form">
      <div className="getnet-keys-info">
        <HtmlTranslate trKey="app.admin.invoices.getnet_keys_form.getnet_keys_info_html" />
      </div>
      <form name="getnetKeysForm">
        <fieldset>
          <div className="getnet-seller-id-input">
            <label htmlFor="getnet_seller_id">{ t('app.admin.invoices.getnet_keys_form.seller_id') } *</label>
            <FabInput id="getnet_seller_id"
              defaultValue={settings.get('getnet_seller_id')}
              addOn={keysAddOn}
              onChange={setApiKey('getnet_seller_id')}
              debounce={200}
              required />
          </div>
          <div className="getnet-client-id-input">
            <label htmlFor="getnet_client_id">{ t('app.admin.invoices.getnet_keys_form.client_id') } *</label>
            <FabInput id="getnet_client_id"
              defaultValue={settings.get('getnet_client_id')}
              addOn={keysAddOn}
              onChange={setApiKey('getnet_client_id')}
              debounce={200}
              required />
          </div>
          <div className="getnet-client-secret-input">
            <label htmlFor="getnet_client_secret">{ t('app.admin.invoices.getnet_keys_form.client_secret') } *</label>
            <FabInput id="getnet_client_secret"
              defaultValue={settings.get('getnet_client_secret')}
              addOn={keysAddOn}
              onChange={setApiKey('getnet_client_secret')}
              debounce={200}
              required />
          </div>
          <div className="getnet-endpoint-input">
            <label htmlFor="getnet_endpoint">{ t('app.admin.invoices.getnet_keys_form.endpoint') } *</label>
            <FabInput id="getnet_endpoint"
              defaultValue={settings.get('getnet_endpoint')}
              addOn={keysAddOn}
              onChange={setApiKey('getnet_endpoint')}
              debounce={200}
              required />
          </div>
        </fieldset>
      </form>
    </div>
  );
};

const GetnetKeysFormWrapper: React.FC<GetnetKeysFormProps> = (props) => {
  return (
    <Loader>
      <GetnetKeysForm {...props} />
    </Loader>
  );
};

export { GetnetKeysFormWrapper as GetnetKeysForm };
