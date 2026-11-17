import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import NAME from '@salesforce/schema/Expense__c.Name';
import AMOUNT from '@salesforce/schema/Expense__c.Amount__c';
import EXPENSE_DATE from '@salesforce/schema/Expense__c.Expense_Date__c';
import POTENTIAL_DUPLICATE from '@salesforce/schema/Expense__c.Potential_Duplicate__c';

// Check which category field name your schema uses (usually Expense_Category__c)
import EXPENSE_CATEGORY from '@salesforce/schema/Expense__c.Expense_Category__c';

const TRAVEL_REQUEST_NAME = 'Expense__c.Travel_Request__r.Name';

const FIELDS = [
    NAME,
    TRAVEL_REQUEST_NAME,
    EXPENSE_CATEGORY,
    AMOUNT,
    EXPENSE_DATE,
    POTENTIAL_DUPLICATE
];

export default class WanderRosterExpenseGuardian extends LightningElement {
    @api recordId;

    record;
    error;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredExpense({ data, error }) {
        if (data) {
            this.record = data;
            this.error = undefined;
        } else if (error) {
            this.record = undefined;
            this.error = error;
        }
    }

    get expenseNumber() {
        return getFieldValue(this.record, NAME) || 'EXP Claim';
    }

    get travelRequestNumber() {
        return (
            getFieldValue(this.record, TRAVEL_REQUEST_NAME) ||
            this.record?.fields?.Travel_Request__r?.displayValue ||
            'Not Assigned'
        );
    }

    get expenseCategory() {
        return getFieldValue(this.record, EXPENSE_CATEGORY) || 'General';
    }

    get amount() {
        return getFieldValue(this.record, AMOUNT) ?? 0;
    }

    get expenseDate() {
        return getFieldValue(this.record, EXPENSE_DATE) || 'Not provided';
    }

    get potentialDuplicate() {
        return getFieldValue(this.record, POTENTIAL_DUPLICATE) === true;
    }
}