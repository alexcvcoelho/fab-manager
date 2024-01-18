import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { BrazillianState } from '../models/brazillian-state';
import { BrazillianCity } from '../models/brazillian-city';
import { BrazillianZipcode } from '../models/brazillian-zipcode';

export default class BrazillianAPI {
  static async states (): Promise<Array<BrazillianState>> {
    const res: AxiosResponse<Array<BrazillianState>> = await apiClient.get('/api/brazillian_data/all_states');
    return res?.data;
  }

  static async cities (uf: string): Promise<Array<BrazillianCity>> {
    const res: AxiosResponse<Array<BrazillianCity>> = await apiClient.get(`/api/brazillian_data/cities/${uf}`);
    return res?.data;
  }

  static async zipcode (zip: string): Promise<BrazillianZipcode> {
    const res: AxiosResponse<BrazillianZipcode> = await apiClient.get(`/api/brazillian_data/zipcode/${zip}`);
    return res?.data;
  }
}
