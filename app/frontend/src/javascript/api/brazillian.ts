import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { BrazillianState } from '../models/brazillian-state';
import { BrazillianCity } from '../models/brazillian-city';

export default class BrazillianAPI {
  static async states (): Promise<Array<BrazillianState>> {
    const res: AxiosResponse<Array<BrazillianState>> = await apiClient.get('/api/brazillian_data/all_states');
    return res?.data;
  }

  static async cities (uf: string): Promise<Array<BrazillianCity>> {
    const res: AxiosResponse<Array<BrazillianCity>> = await apiClient.get(`/api/brazillian_data/cities/${uf}`);
    return res?.data;
  }
}
