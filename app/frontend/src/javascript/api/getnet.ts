import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart } from '../models/payment';
import { User } from '../models/user';
import {
  CreatePaymentResponse,
  CreateTokenResponse,
  SdkTestResponse,
  Card
} from '../models/getnet';
import { Invoice } from '../models/invoice';

export default class GetnetAPI {
  static async sdkTest (endpoint: string, sellerId: string, clientId: string, clientSecret: string): Promise<SdkTestResponse> {
    const res: AxiosResponse<SdkTestResponse> = await apiClient.post('/api/getnet/sdk_test', { endpoint, seller_id: sellerId, client_id: clientId, client_secret: clientSecret });
    return res?.data;
  }

  static async tokenCard (cardNumber: string, customer: User): Promise<CreateTokenResponse> {
    const res: AxiosResponse<CreateTokenResponse> = await apiClient.post('/api/getnet/token_card', { card_number: cardNumber, customer_id: customer.id });
    return res?.data;
  }

  static async createPayment (card: Card, cart: ShoppingCart, customer: User): Promise<CreatePaymentResponse> {
    const res: AxiosResponse<CreatePaymentResponse> = await apiClient.post('/api/getnet/create_payment', { cart_items: cart, customer_id: customer.id, card });
    return res?.data;
  }

  static async confirm (orderId: string, cart: ShoppingCart): Promise<Invoice> {
    const res: AxiosResponse<Invoice> = await apiClient.post('/api/getnet/confirm_payment', { cart_items: cart, order_id: orderId });
    return res?.data;
  }
}
