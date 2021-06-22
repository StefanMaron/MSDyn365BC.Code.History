codeunit 5350 "CRM Statistics Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        UpdateStatisticsAndInvoices(GetLastLogEntryNo);
    end;

    var
        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        RecordFoundTxt: Label '%1 %2 was not found.', Comment = '%1 is a table name, e.g. Customer, %2 is a number, e.g. Customer 12344 was not found.';
        AccountStatisticsUpdatedMsg: Label 'Updated account statistics. ';
        InvoiceStatusUpdatedMsg: Label 'Updated payment status of sales invoices.';
        CRMProductName: Codeunit "CRM Product Name";

    local procedure UpdateStatisticsAndInvoices(JobLogEntryNo: Integer)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Text;
    begin
        CRMConnectionSetup.Get();
        if not CRMConnectionSetup."Is Enabled" then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL);

        ConnectionName := Format(CreateGuid);
        CRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        SetDefaultTableConnection(
          TABLECONNECTIONTYPE::CRM, CRMConnectionSetup.GetDefaultCRMConnection(ConnectionName));

        UpdateAccountStatistics(JobLogEntryNo);

        UpdateInvoices(JobLogEntryNo);

        CRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure UpdateAccountStatistics(JobLogEntryNo: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        RecRef: array[2] of RecordRef;
        ErrorText: Text;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
    begin
        IntegrationTableSynch.BeginIntegrationSynchJobLoging(
          TABLECONNECTIONTYPE::CRM, CODEUNIT::"CRM Statistics Job", JobLogEntryNo, DATABASE::Customer);

        CRMIntegrationRecord.SetRange("Table ID", DATABASE::Customer);
        CRMIntegrationRecord.SetRange(Skipped, false);
        if CRMIntegrationRecord.FindSet(true) then
            repeat
                Clear(RecRef);
                SynchActionType := UpdateCRMAccountStatisticsForCoupledCustomer(CRMIntegrationRecord, RecRef[1], RecRef[2], ErrorText);
                if SynchActionType = SynchActionType::Fail then begin
                    CRMIntegrationRecord."Last Synch. CRM Job ID" := IntegrationTableSynch.LogSynchError(RecRef[1], RecRef[2], ErrorText);
                    CRMIntegrationRecord."Last Synch. CRM Result" := CRMIntegrationRecord."Last Synch. CRM Result"::Failure;
                    CRMIntegrationRecord.Skipped := true;
                    CRMIntegrationRecord.Modify();
                end else
                    IntegrationTableSynch.IncrementSynchJobCounters(SynchActionType);
            until CRMIntegrationRecord.Next = 0;

        IntegrationTableSynch.EndIntegrationSynchJobWithMsg(GetAccStatsUpdateFinalMessage);
    end;

    local procedure UpdateInvoices(JobLogEntryNo: Integer)
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        Counter: Integer;
    begin
        IntegrationTableSynch.BeginIntegrationSynchJobLoging(
          TABLECONNECTIONTYPE::CRM, CODEUNIT::"CRM Statistics Job", JobLogEntryNo, DATABASE::Customer);

        Counter := UpdateStatusOfPaidInvoices('');
        IntegrationTableSynch.UpdateSynchJobCounters(SynchActionType::Modify, Counter);

        IntegrationTableSynch.EndIntegrationSynchJobWithMsg(GetInvStatusUpdateFinalMessage);
    end;

    local procedure UpdateCRMAccountStatisticsForCoupledCustomer(CRMIntegrationRecord: Record "CRM Integration Record"; var CustomerRecRef: RecordRef; var CRMAccountRecRef: RecordRef; var ErrorText: Text): Integer
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        RecId: RecordId;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        CustomerExists: Boolean;
        CRMAccountExists: Boolean;
    begin
        CRMIntegrationRecord.FindRecordId(RecId);
        CustomerExists := CustomerRecRef.Get(RecId);
        if CustomerExists then
            CustomerRecRef.SetTable(Customer);
        CRMAccountExists := CRMAccount.Get(CRMIntegrationRecord."CRM ID");
        if CRMAccountExists then
            CRMAccountRecRef.GetTable(CRMAccount);
        if CustomerExists and CRMAccountExists then
            exit(CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount));

        if not CRMAccountExists then
            ErrorText := StrSubstNo(RecordFoundTxt, CRMAccount.TableCaption, CRMIntegrationRecord."CRM ID");
        if not CustomerExists then
            ErrorText := StrSubstNo(RecordFoundTxt, Customer.TableCaption, RecId);

        exit(SynchActionType::Fail);
    end;

    procedure CreateOrUpdateCRMAccountStatistics(Customer: Record Customer; var CRMAccount: Record "CRM Account"): Integer
    var
        CRMAccountStatistics: Record "CRM Account Statistics";
        xCRMAccountStatistics: Record "CRM Account Statistics";
        LcyCRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
    begin
        FindCRMAccountStatistics(CRMAccountStatistics, CRMAccount);
        xCRMAccountStatistics := CRMAccountStatistics;
        Customer.CalcFields("Balance (LCY)", "Outstanding Orders (LCY)", "Shipped Not Invoiced (LCY)",
          "Outstanding Invoices (LCY)", "Outstanding Serv. Orders (LCY)", "Serv Shipped Not Invoiced(LCY)",
          "Outstanding Serv.Invoices(LCY)");
        with CRMAccountStatistics do begin
            Name := Customer.Name;
            "Customer No" := Customer."No.";
            "Balance (LCY)" := Customer."Balance (LCY)";
            "Outstanding Orders (LCY)" := Customer."Outstanding Orders (LCY)";
            "Shipped Not Invoiced (LCY)" := Customer."Shipped Not Invoiced (LCY)";
            "Outstanding Invoices (LCY)" := Customer."Outstanding Invoices (LCY)";
            "Outstanding Serv Orders (LCY)" := Customer."Outstanding Serv. Orders (LCY)";
            "Serv Shipped Not Invd (LCY)" := Customer."Serv Shipped Not Invoiced(LCY)";
            "Outstd Serv Invoices (LCY)" := Customer."Outstanding Serv.Invoices(LCY)";
            "Total (LCY)" := Customer.GetTotalAmountLCY;
            "Credit Limit (LCY)" := Customer."Credit Limit (LCY)";
            "Overdue Amounts (LCY)" := Customer.CalcOverdueBalance;
            "Overdue Amounts As Of Date" := WorkDate;
            "Total Sales (LCY)" := Customer.GetSalesLCY;
            "Invd Prepayment Amount (LCY)" := Customer.GetInvoicedPrepmtAmountLCY;
            TransactionCurrencyId := CRMSynchHelper.FindNAVLocalCurrencyInCRM(LcyCRMTransactioncurrency);
            if xCRMAccountStatistics."Customer No" = '' then begin
                Modify;
                exit(SynchActionType::Insert);
            end;
            if IsCRMAccountStatisticsModified(xCRMAccountStatistics, CRMAccountStatistics) then begin
                Modify;
                exit(SynchActionType::Modify);
            end;
            exit(SynchActionType::IgnoreUnchanged);
        end;
    end;

    procedure GetAccStatsUpdateFinalMessage(): Text
    begin
        exit(AccountStatisticsUpdatedMsg);
    end;

    procedure GetInvStatusUpdateFinalMessage(): Text
    begin
        exit(InvoiceStatusUpdatedMsg);
    end;

    local procedure IsCRMAccountStatisticsModified(xCRMAccountStatistics: Record "CRM Account Statistics"; CRMAccountStatistics: Record "CRM Account Statistics"): Boolean
    var
        RecRef: array[2] of RecordRef;
        FieldRef: array[2] of FieldRef;
        I: Integer;
    begin
        RecRef[1].GetTable(xCRMAccountStatistics);
        RecRef[2].GetTable(CRMAccountStatistics);
        for I := 1 to RecRef[1].FieldCount do begin
            FieldRef[1] := RecRef[1].FieldIndex(I);
            if FieldRef[1].Number >= CRMAccountStatistics.FieldNo(Name) then begin // non system CRM fields starts from Name
                FieldRef[2] := RecRef[2].FieldIndex(I);
                if FieldRef[1].Value <> FieldRef[2].Value then
                    exit(true);
            end;
        end;
        RecRef[1].Close;
        RecRef[2].Close;
    end;

    local procedure InitCRMAccountStatistics(var CRMAccountStatistics: Record "CRM Account Statistics")
    begin
        with CRMAccountStatistics do begin
            Init;
            AccountStatisticsId := CreateGuid;
            // Set all Money type fields to 1 temporarily, because if they have always been zero they show as '--' in CRM
            "Balance (LCY)" := 1;
            "Total (LCY)" := 1;
            "Credit Limit (LCY)" := 1;
            "Overdue Amounts (LCY)" := 1;
            "Total Sales (LCY)" := 1;
            "Invd Prepayment Amount (LCY)" := 1;
            "Outstanding Orders (LCY)" := 1;
            "Shipped Not Invoiced (LCY)" := 1;
            "Outstanding Invoices (LCY)" := 1;
            "Outstanding Serv Orders (LCY)" := 1;
            "Serv Shipped Not Invd (LCY)" := 1;
            "Outstd Serv Invoices (LCY)" := 1;
            Insert;
        end;
    end;

    local procedure FindCRMAccountStatistics(var CRMAccountStatistics: Record "CRM Account Statistics"; var CRMAccount: Record "CRM Account")
    begin
        if IsNullGuid(CRMAccount.AccountStatiticsId) then begin
            InitCRMAccountStatistics(CRMAccountStatistics);
            CRMAccount.AccountStatiticsId := CRMAccountStatistics.AccountStatisticsId;
            ModifyCRMAccount(CRMAccount);
        end else
            CRMAccountStatistics.Get(CRMAccount.AccountStatiticsId);
    end;

    local procedure ModifyCRMAccount(var CRMAccount: Record "CRM Account")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        with CRMAccount do
            if not CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(AccountId, DATABASE::Customer, ModifiedOn) then begin
                Modify;
                CRMIntegrationRecord.SetLastSynchCRMModifiedOn(AccountId, DATABASE::Customer, ModifiedOn);
            end else
                Modify;
    end;

    procedure UpdateStatusOfPaidInvoices(CustomerNo: Code[20]) UpdatedInvoiceCounter: Integer
    var
        CRMSynchStatus: Record "Crm Synch Status";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CurrCLENo: Integer;
        ForAllCustomers: Boolean;
    begin

        if CRMSynchStatus.IsEmpty then begin
            CRMIntegrationManagement.InitializeCRMSynchStatus();
        end;
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Posting Date");
        DtldCustLedgEntry.SetFilter("Entry No.", '>%1', CRMSynchStatus."Last Update Invoice Entry No.");
        ForAllCustomers := CustomerNo = '';
        if not ForAllCustomers then
            DtldCustLedgEntry.SetRange("Customer No.", CustomerNo);
        if DtldCustLedgEntry.FindSet then begin
            CurrCLENo := DtldCustLedgEntry."Cust. Ledger Entry No.";
            repeat
                if CurrCLENo <> DtldCustLedgEntry."Cust. Ledger Entry No." then begin
                    UpdatedInvoiceCounter += UpdateInvoice(CurrCLENo);
                    CurrCLENo := DtldCustLedgEntry."Cust. Ledger Entry No.";
                end;
            until DtldCustLedgEntry.Next = 0;
            UpdatedInvoiceCounter += UpdateInvoice(CurrCLENo);
            if ForAllCustomers then
                CRMSynchStatus.UpdateLastUpdateInvoiceEntryNo;
        end;
    end;

    local procedure UpdateInvoice(CustLedgEntryNo: Integer): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMInvoice: Record "CRM Invoice";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        if CustLedgerEntry.Get(CustLedgEntryNo) then
            if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice then
                if SalesInvHeader.Get(CustLedgerEntry."Document No.") then
                    if CRMIntegrationRecord.FindByRecordID(SalesInvHeader.RecordId) then
                        if CRMInvoice.Get(CRMIntegrationRecord."CRM ID") then
                            exit(CRMSynchHelper.UpdateCRMInvoiceStatusFromEntry(CRMInvoice, CustLedgerEntry));
    end;

    [EventSubscriber(ObjectType::Table, 472, 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSynchStatus: Record "CRM Synch Status";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with Sender do
            if ("Object Type to Run" = "Object Type to Run"::Codeunit) and ("Object ID to Run" = CODEUNIT::"CRM Statistics Job") then
                if CRMConnectionSetup.Get and CRMConnectionSetup."Is Enabled" and CRMSynchStatus.Get then
                    Result :=
                      DetailedCustLedgEntry.FindLast and
                      (CRMSynchStatus."Last Update Invoice Entry No." < DetailedCustLedgEntry."Entry No.");
    end;
}

