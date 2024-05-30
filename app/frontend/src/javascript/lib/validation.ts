// Provides regular expressions to validate user inputs
export default class ValidationLib {
  static urlRegex = /^(https?:\/\/)(([^.]+)\.)+(.{2,30})(\/.*)*\/?$/;
  static endpointRegex = /^\/?([-._~:?#[\]@!$&'()*+,;=%\w]+\/?)*$/;
  static phoneRegex = /^((00|\+)\d{2,3})?[\d -]{4,14}$/;
  static expirationCardRegex = /^(0[1-9]|1[0-2])\/\d{2}$/;
  static cardNumberRegex = /^\d{4} \d{4} \d{4} (\d{4}|\d{3}|\d{2})$/;
  static cvvRegex = /^\d{3,4}$/;
}
