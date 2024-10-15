table 7822 "MS-QBO Invoice"
{
    Caption = 'MS-QBO Invoice';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Text[250])
        {
            Caption = 'Id';
        }
        field(2; SyncToken; Text[250])
        {
            Caption = 'SyncToken';
        }
        field(3; MetaData; BLOB)
        {
            Caption = 'MetaData';
        }
        field(4; "MetaData CreateTime"; DateTime)
        {
            Caption = 'MetaData CreateTime';
        }
        field(5; "MetaData LastUpdatedTime"; DateTime)
        {
            Caption = 'MetaData LastUpdatedTime';
        }
        field(6; CustomField; BLOB)
        {
            Caption = 'CustomField';
        }
        field(7; DocNumber; Text[21])
        {
            Caption = 'DocNumber';
            Description = 'Reference number for the transaction.';
        }
        field(8; TxnDate; Date)
        {
            Caption = 'TxnDate';
            Description = 'The date entered by the user when this transaction occurred.For posting transactions, this is the posting date that affects the financial statements. If the date is not supplied, the current date on the server is used.';
        }
        field(9; DepartmentRef; BLOB)
        {
            Caption = 'DepartmentRef';
            Description = 'A reference to a Department object specifying the location of the transaction. Default is null.';
        }
        field(10; CurrencyRef; BLOB)
        {
            Caption = 'CurrencyRef';
            Description = 'Reference to the currency in which all amounts on the associated transaction are expressed. If not returned, currency for the transaction is the home currency of the company.';
        }
        field(11; ExchangeRate; Decimal)
        {
            Caption = 'ExchangeRate';
            Description = 'Default is 1, applicable if multicurrency is enabled for the company.';
        }
        field(12; PrivateNote; BLOB)
        {
            Caption = 'PrivateNote';
            Description = 'User entered, organization-private note about the transaction.String, max of 4000 chars.';
        }
        field(13; LinkedTxn; BLOB)
        {
            Caption = 'LinkedTxn';
            Description = 'Zero or more related transactions to this Invoice object.';
        }
        field(14; Line; BLOB)
        {
            Caption = 'Line';
            Description = 'Individual line items of a transaction.';
        }
        field(15; TxnTaxDetail; BLOB)
        {
            Caption = 'TxnTaxDetail';
            Description = 'TxnTaxDetail  This data type provides information for taxes charged on the transaction as a whole. It captures the details sales taxes calculated for the transaction based on the tax codes referenced by the transaction. This can be calculated by QuickBooks business logic or you may supply it when adding a transaction.';
        }
        field(16; CustomerRef; BLOB)
        {
            Caption = 'CustomerRef';
            Description = 'Reference to a customer or job. Query the Customer name list resource to determine the appropriate Customer object to reference here.';
        }
        field(17; CustomerMemo; BLOB)
        {
            Caption = 'CustomerMemo';
            Description = 'User-entered message to the customer; this message is visible to end user on their transactions.';
        }
        field(18; BillAddr; BLOB)
        {
            Caption = 'BillAddr';
            Description = 'Bill-to address of the Invoice. If BillAddris not specified, and a default Customer:BillingAddr is specified in QuickBooks for this customer, the default bill-to address is used by QuickBooks.';
        }
        field(19; ShipAddr; BLOB)
        {
            Caption = 'ShipAddr';
            Description = 'Identifies the address where the goods must be shipped. If ShipAddris not specified, and a default Customer:ShippingAddr is specified in QuickBooks for this customer, the default ship-to address will be used by QuickBooks.';
        }
        field(20; ClassRef; BLOB)
        {
            Caption = 'ClassRef';
            Description = 'Reference to the Class associated with the transaction.';
        }
        field(21; SalesTermRef; BLOB)
        {
            Caption = 'SalesTermRef';
            Description = 'Reference to the sales term associated with the transaction. Query the Term name list resource to determine the appropriate Term object to reference here.';
        }
        field(22; DueDate; Date)
        {
            Caption = 'DueDate';
            Description = 'Date when the payment of the transaction is due. If date is not provided, the number of days specified in SalesTermRef added the transaction date will be used.';
        }
        field(23; GlobalTaxCalculation; BLOB)
        {
            Caption = 'GlobalTaxCalculation';
            Description = 'Default is TaxExcluded. Method in which tax is applied. Allowed values are: TaxExcluded, TaxInclusive, and NotApplicable.';
        }
        field(24; ShipMethodRef; BLOB)
        {
            Caption = 'ShipMethodRef';
            Description = 'Reference to the ShipMethod associated with the transaction. There is no shipping method list. Reference resolves to a string.';
        }
        field(25; ShipDate; Date)
        {
            Caption = 'ShipDate';
            Description = 'Date for delivery of goods or services.';
        }
        field(26; TrackingNum; Text[250])
        {
            Caption = 'TrackingNum';
            Description = 'Shipping provider''s tracking number for the delivery of the goods associated with the transaction.';
        }
        field(27; TotalAmt; Decimal)
        {
            Caption = 'TotalAmt';
            Description = 'Indicates the total amount of the transaction. This includes the total of all the charges, allowances, and taxes. Calculated by QuickBooks business logic; any value you supply is over-written by QuickBooks.';
        }
        field(28; HomeTotalAmt; Decimal)
        {
            Caption = 'HomeTotalAmt';
            Description = 'Applicable if multicurrency is enabled for the company. Total amount of the transaction in the home currency. Includes the total of all the charges, allowances and taxes. Calculated by QuickBooks business logic.';
        }
        field(29; ApplyTaxAfterDiscount; Boolean)
        {
            Caption = 'ApplyTaxAfterDiscount';
            Description = 'If false or null, calculate the sales tax first, and then apply the discount. If true, subtract the discount first and then calculate the sales tax.';
        }
        field(30; PrintStatus; Text[13])
        {
            Caption = 'PrintStatus';
            Description = 'Valid values: NotSet, NeedToPrint, PrintComplete.';
        }
        field(31; EmailStatus; Text[10])
        {
            Caption = 'EmailStatus';
            Description = 'Valid values: NotSet,NeedToSend, EmailSent.';
        }
        field(32; BillEmail; BLOB)
        {
            Caption = 'BillEmail';
            Description = 'Identifies the e-mail address where the invoice is sent. If EmailStatus=NeedToSend, BillEmailis a required input.';
        }
        field(33; DeliveryInfo; Text[250])
        {
            Caption = 'DeliveryInfo';
            Description = 'Email delivery information. Returned when a request has been made to deliver email with the send operation.';
        }
        field(34; Balance; Decimal)
        {
            Caption = 'Balance';
            Description = 'The balance reflecting any payments made against the transaction. Initially set to the value of TotalAmt. A Balance of 0 indicates the invoice is fully paid. Calculated by QuickBooks business logic;';
        }
        field(35; HomeBalance; Decimal)
        {
            Caption = 'HomeBalance';
            Description = 'Applicable if multicurrency is enabled for the company.Convenience field containing the amount in Balance expressed in terms of the home currency.Calculated by QuickBooks business logic.';
        }
        field(36; TxnSource; Text[250])
        {
            Caption = 'TxnSource';
            Description = 'Used internally to specify originating source of a credit card transaction.';
        }
        field(37; Deposit; Text[30])
        {
            Caption = 'Deposit';
            Description = 'The deposit made towards this invoice.';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

