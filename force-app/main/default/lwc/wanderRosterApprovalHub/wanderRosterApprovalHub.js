import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isGuest from '@salesforce/user/isGuest';

import getUserContext from '@salesforce/apex/WanderRosterPortalApprovalController.getUserContext';
import getTravelRequests from '@salesforce/apex/WanderRosterPortalApprovalController.getTravelRequests';
import updateRequestStatus from '@salesforce/apex/WanderRosterPortalApprovalController.updateRequestStatus';
import submitTravelRequest from '@salesforce/apex/WanderRosterPortalApprovalController.submitTravelRequest';

export default class WanderRosterApprovalHub extends LightningElement {
    @track userName = '';
    @track userEmail = '';
    @track userRoleCategory = 'Employee';
    @track isApprover = false;

    // Form inputs
    @track destination = '';
    @track purpose = '';
    @track estimatedCost = null;
    @track startDate = '';
    @track endDate = '';

    @track pendingList = [];
    @track isLoading = false;
    wiredRequestsResult;

    // Metrics Dashboard
    @track totalRequestsCount = 0;
    @track employeeCount = 0;
    @track pendingRequestsCount = 0;
    @track totalApprovedAmount = 0;
    @track totalBudgetAmount = 0;

    get isUserLoggedIn() {
        return !isGuest;
    }

    get avatarInitials() {
        return this.userName 
            ? this.userName.split(' ').map(n => n[0]).join('').toUpperCase() 
            : 'U';
    }

    get hasRequests() {
        return this.pendingList && this.pendingList.length > 0;
    }

    get cardTitle() {
        return this.isApprover ? 'Travel Requests from Employees' : 'My Travel Requests';
    }

    get isEmployeeView() {
        return this.userRoleCategory === 'Employee';
    }

    @wire(getUserContext)
    wiredContext({ error, data }) {
        if (data) {
            this.userName = data.userName;
            this.userEmail = data.userEmail;
            this.userRoleCategory = data.roleCategory;
            this.isApprover = data.isApprover;
        } else if (error) {
            console.error('Error loading user context:', error);
        }
    }

    @wire(getTravelRequests)
    wiredRequests(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            const records = result.data;
            this.totalRequestsCount = records.length;

            const uniqueEmployees = new Set();
            let pendingCount = 0;
            let approvedSum = 0;
            let totalSum = 0;

            records.forEach(req => {
                if (req.createdById) {
                    uniqueEmployees.add(req.createdById);
                }
                const cost = req.estimatedCost || 0;
                totalSum += cost;

                const statusStr = (req.status || '').toLowerCase();
                if (statusStr.includes('pending') || statusStr === 'submitted' || statusStr === 'draft') {
                    pendingCount++;
                } else if (statusStr === 'approved' || statusStr === 'accept') {
                    approvedSum += cost;
                }
            });

            this.employeeCount = uniqueEmployees.size;
            this.pendingRequestsCount = pendingCount;
            this.totalApprovedAmount = approvedSum;
            this.totalBudgetAmount = totalSum;

            this.pendingList = records.map(req => {
                let badgeClass = 'badge-status ';
                const status = (req.status || '').toLowerCase();
                
                if (status === 'approved' || status === 'accept') {
                    badgeClass += 'badge-approved';
                } else if (status === 'rejected' || status === 'reject') {
                    badgeClass += 'badge-rejected';
                } else {
                    badgeClass += 'badge-pending';
                }

                return { 
                    ...req, 
                    badgeClass
                };
            });
        } else if (result.error) {
            console.error('Error fetching travel requests:', result.error);
        }
    }

    handleDestinationChange(event) {
        this.destination = event.target.value;
    }

    handlePurposeChange(event) {
        this.purpose = event.target.value;
    }

    handleCostChange(event) {
        this.estimatedCost = event.target.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleSubmitRequest() {
        if (!this.destination || !this.purpose || !this.estimatedCost || !this.startDate || !this.endDate) {
            this.showToast('Missing Fields', 'Please complete Destination, Purpose, Cost, Start Date, and End Date.', 'error');
            return;
        }

        if (this.startDate > this.endDate) {
            this.showToast('Invalid Dates', 'End Date cannot be earlier than Start Date.', 'error');
            return;
        }

        this.isLoading = true;
        submitTravelRequest({
            destination: this.destination,
            purpose: this.purpose,
            estimatedCost: parseFloat(this.estimatedCost),
            startDate: this.startDate,
            endDate: this.endDate
        })
            .then(() => {
                this.showToast('Success', 'Travel request saved and submitted successfully.', 'success');
                this.destination = '';
                this.purpose = '';
                this.estimatedCost = null;
                this.startDate = '';
                this.endDate = '';
                return refreshApex(this.wiredRequestsResult);
            })
            .catch(error => {
                this.showToast('Submission Error', error.body?.message || 'Unable to save record.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleDecision(event) {
        const requestId = event.target.dataset.id;
        const action = event.target.dataset.action;
        let targetStatus = 'Pending Approval';

        if (action === 'Accept') {
            targetStatus = 'Approved';
        } else if (action === 'Reject') {
            targetStatus = 'Rejected';
        } else if (action === 'Pending') {
            targetStatus = 'Pending Approval';
        }

        this.isLoading = true;
        updateRequestStatus({ requestId: requestId, newStatus: targetStatus })
            .then(() => {
                this.showToast('Updated', `Request marked as ${targetStatus}.`, 'success');
                return refreshApex(this.wiredRequestsResult);
            })
            .catch(error => {
                this.showToast('Update Failed', error.body?.message || 'Error updating status.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredRequestsResult).finally(() => {
            this.isLoading = false;
        });
    }

    handleLogout() {
        window.location.replace('/wanderportal/secur/logout.jsp');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}