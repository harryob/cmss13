import { ADMIN_CHANNELS, CHANNELS } from '../constants';
import { getHistoryAt, getHistoryLength } from '../helpers';
import { Modal } from '../types';

/**  Sets the input value to chat history at index historyCounter. */
export const handleViewHistory = function (this: Modal) {
  const { channel } = this.state;
  const { historyCounter, admin } = this.fields;
  const usedChannels = admin ? ADMIN_CHANNELS : CHANNELS;
  if (historyCounter > 0 && getHistoryLength()) {
    this.fields.value = getHistoryAt(historyCounter);
    if (channel < 2) {
      this.timers.typingThrottle();
    }
    this.setState({ buttonContent: historyCounter, edited: true });
    this.events.onSetSize(0);
  } else {
    /** Restores any saved history */
    this.fields.value = this.fields.tempHistory;
    this.fields.tempHistory = '';
    this.setState({
      buttonContent: usedChannels[channel],
      edited: true,
    });
  }
  this.events.onSetSize(this.fields.value?.length);
};
