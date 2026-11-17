import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserPortalRole from '@salesforce/apex/WanderPortalExpenseController.getUserPortalRole';
import getApprovedTravelRequests from '@salesforce/apex/WanderPortalExpenseController.getApprovedTravelRequests';
import getExpensesForRequest from '@salesforce/apex/WanderPortalExpenseController.getExpensesForRequest';
import createExpenseClaim from '@salesforce/apex/WanderPortalExpenseController.createExpenseClaim';

export default class WanderRosterPortalReimbursementV2 extends LightningElement {
    @track isEmployee = false;
    @track travelOptions = [];
    @track expenses = [];
    @track isLoading = false;

    selectedTravelId = '';
    selectedRequestLabel = '';
    category = 'Meals';
    amount = null;
    expenseDate = new Date().toISOString().slice(0, 10);
    description = '';

    wiredExpensesResult;

    categoryOptions = [
        { label: 'Meals & Dining', value: 'Meals' },
        { label: 'Transport (Flight / Train / Fuel)', value: 'Transport' },
        { label: 'Hotel & Lodging', value: 'Lodging' },
        { label: 'Local Taxi / Commute', value: 'Local Commute' },
        { label: 'Other', value: 'Other' }
    ];

    // Check user role
    @wire(getUserPortalRole)
    wiredRole({ data, error }) {
        if (data) {
            this.isEmployee = data.isEmployee;
        }
    }

    // Load employee's approved travel requests
    @wire(getApprovedTravelRequests)
    wiredTravel({ data, error }) {
        if (data && data.length > 0) {
            this.travelOptions = data.map(item => ({
                label: item.label,
                value: item.id
            }));
            if (!this.selectedTravelId) {
                this.selectedTravelId = this.travelOptions[0].value;
                this.selectedRequestLabel = this.travelOptions[0].label;
            }
        }
    }

    // Load expenses strictly for the currently selected travel request
    @wire(getExpensesForRequest, { travelRequestId: '$selectedTravelId' })
    wiredExpenses(result) {
        this.wiredExpensesResult = result;
        const { data, error } = result;
        if (data) {
            this.expenses = data.map(claim => ({
                ...claim,
                badgeClass: this.computeBadgeClass(claim.status)
            }));
        } else {
            this.expenses = [];
        }
    }

    computeBadgeClass(status) {
        const s = (status || '').toLowerCase();
        if (s.includes('paid')) return 'status-badge status-paid';
        if (s.includes('approv')) return 'status-badge status-approved';
        if (s.includes('reject')) return 'status-badge status-rejected';
        return 'status-badge status-pending';
    }

    handleTravelChange(e) {
        this.selectedTravelId = e.detail.value;
        const selected = this.travelOptions.find(opt => opt.value === this.selectedTravelId);
        this.selectedRequestLabel = selected ? selected.label : '';
    }

    handleCategoryChange(e) { this.category = e.detail.value; }
    handleAmountChange(e) { this.amount = parseFloat(e.target.value); }
    handleDateChange(e) { this.expenseDate = e.target.value; }
    handleDescriptionChange(e) { this.description = e.target.value; }

    handleSubmitExpense() {
        if (!this.selectedTravelId) {
            this.showToast('Select Request', 'Please select a travel request.', 'warning');
            return;
        }
        if (!this.amount || this.amount <= 0) {
            this.showToast('Invalid Amount', 'Please enter a valid expense amount in â‚¹.', 'warning');
            return;
        }

        this.isLoading = true;
        createExpenseClaim({
            travelRequestId: this.selectedTravelId,
            category: this.category,
            amount: this.amount,
            expenseDate: this.expenseDate,
            description: this.description
        })
            .then(() => {
                this.showToast('Submitted', 'Expense claim submitted under ' + this.selectedRequestLabel, 'success');
                this.amount = null;
                this.description = '';
                return refreshApex(this.wiredExpensesResult);
            })
            .catch(err => {
                this.showToast('Error', err.body?.message || 'Could not submit claim.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
