import { LightningElement, api, wire, track } from 'lwc';
import getTravelInsights from '@salesforce/apex/TravelInsightsController.getTravelInsights';

export default class TravelItineraryInsights extends LightningElement {
    @api recordId;
    @track insights = {};
    @track error;

    @wire(getTravelInsights, { recordId: '$recordId' })
    wiredInsights({ error, data }) {
        if (data) {
            this.insights = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'Error loading travel insights.';
            this.insights = {};
        }
    }

    get hasData() {
        return this.insights && this.insights.travelName;
    }

    get badgeClass() {
        const status = (this.insights.status || '').toLowerCase();
        if (status.includes('approv') || status.includes('accept')) {
            return 'badge-status badge-approved';
        } else if (status.includes('reject')) {
            return 'badge-status badge-rejected';
        }
        return 'badge-status badge-pending';
    }
}