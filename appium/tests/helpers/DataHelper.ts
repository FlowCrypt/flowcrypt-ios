import moment from 'moment';

class DataHelper {
  static uniqueValue() {
    return Math.random().toString(36).substring(2);
  }
  static convertStringToDate = (date: string) => {
    return moment(date.replace('at', '')).utcOffset(0);
  };
}

export default DataHelper;
