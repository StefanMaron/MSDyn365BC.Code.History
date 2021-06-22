codeunit 361 MoveEntries
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Item Ledger Entry" = rm,
                  TableData "Job Ledger Entry" = rm,
                  TableData "Res. Ledger Entry" = rm,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rm,
                  TableData "Value Entry" = rm,
                  TableData "Avg. Cost Adjmt. Entry Point" = rd,
                  TableData "Inventory Adjmt. Entry (Order)" = rm,
                  TableData "Service Ledger Entry" = rm,
                  TableData "Warranty Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'You cannot delete %1 %2 because it has ledger entries in a fiscal year that has not been closed yet.';
        Text001: Label 'You cannot delete %1 %2 because there are one or more open ledger entries.';
        Text002: Label 'There are item entries that have not been adjusted for item %1. ';
        Text003: Label 'If you delete this item the inventory valuation will be incorrect. ';
        Text004: Label 'Use the %2 batch job before deleting the item.';
        Text005: Label 'Adjust Cost - Item Entries';
        Text006: Label 'You cannot delete %1 %2 because it has ledger entries.';
        Text007: Label 'You cannot delete %1 %2 because there are outstanding purchase order lines.';
        Text008: Label 'There are item entries that have not been completely invoiced for item %1. ';
        Text009: Label 'Invoice all item entries before deleting the item.';
        AccountingPeriod: Record "Accounting Period";
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ResLedgEntry: Record "Res. Ledger Entry";
        JobLedgEntry: Record "Job Ledger Entry";
        PurchOrderLine: Record "Purchase Line";
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        ValueEntry: Record "Value Entry";
        AvgCostAdjmt: Record "Avg. Cost Adjmt. Entry Point";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ServLedgEntry: Record "Service Ledger Entry";
        WarrantyLedgEntry: Record "Warranty Ledger Entry";
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        ServContract: Record "Service Contract Header";
        CannotDeleteGLBudgetEntriesErr: Label 'You cannot delete G/L account %1 because it contains budget ledger entries after %2 for G/L budget name %3.', Comment = '%1 - G/L Account No., %2 - Date, %3 - G/L Budget Name. You cannot delete G/L Account 1000 because it has budget ledger entries\ after 25/01/2018 in G/L Budget Name = Budget_2018.';
        Text013: Label 'You cannot delete %1 %2 because prepaid contract entries exist in %3.';
        Text014: Label 'You cannot delete %1 %2, because open prepaid contract entries exist in %3.';
        Text015: Label 'You cannot delete %1 %2 because there are outstanding purchase return order lines.';
        TimeSheetLinesErr: Label 'You cannot delete job %1 because it has open or submitted time sheet lines.', Comment = 'You cannot delete job JOB001 because it has open or submitted time sheet lines.';
        CannotDeleteBecauseInInvErr: Label 'You cannot delete %1 because it is used in some invoices.', Comment = '%1 = the object to be deleted (example: Item, Customer).';
        GLAccDeleteClosedPeriodsQst: Label 'Note that accounting regulations may require that you save accounting data for a certain number of years. Are you sure you want to delete the G/L account?';
        CannotDeleteGLAccountWithEntriesInOpenFiscalYearErr: Label 'You cannot delete G/L account %1 because it has ledger entries in a fiscal year that has not been closed yet.', Comment = '%1 - G/L Account No. You cannot delete G/L Account 1000 because it has ledger entries in a fiscal year that has not been closed yet.';
        CannotDeleteGLAccountWithEntriesAfterDateErr: Label 'You cannot delete G/L account %1 because it has ledger entries posted after %2.', Comment = '%1 - G/L Account No., %2 - Date. You cannot delete G/L Account 1000 because it has ledger entries posted after 01-01-2010.';
        CannotDeleteBecauseServiceContractErr: Label 'You cannot delete customer %1 because there is at least one not cancelled Service Contract for this customer.', Comment = '%1 - Customer No.';

    procedure MoveGLEntries(GLAcc: Record "G/L Account")
    var
        GLSetup: Record "General Ledger Setup";
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
        NewGLAccNo: Code[20];
    begin
        OnBeforeMoveGLEntries(GLAcc, NewGLAccNo);

        GLSetup.Get();

        CheckGLAccountEntries(GLAcc, GLSetup);

        if GLSetup."Check G/L Account Usage" then
            CalcGLAccWhereUsed.DeleteGLNo(GLAcc."No.");

        GLEntry.Reset();
        GLEntry.SetCurrentKey("G/L Account No.");
        GLEntry.SetRange("G/L Account No.", GLAcc."No.");
        GLEntry.ModifyAll("G/L Account No.", NewGLAccNo);

        OnAfterMoveGLEntries(GLAcc, GLEntry);
    end;

    procedure MoveCustEntries(Cust: Record Customer)
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        NewCustNo: Code[20];
    begin
        OnBeforeMoveCustEntries(Cust, NewCustNo);

        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            CustLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not CustLedgEntry.IsEmpty then begin
            if EnvInfoProxy.IsInvoicing then
                Error(
                  CannotDeleteBecauseInInvErr,
                  Cust.TableCaption);

            Error(
              Text000,
              Cust.TableCaption, Cust."No.");
        end;

        CustLedgEntry.Reset();
        if not CustLedgEntry.SetCurrentKey("Customer No.", Open) then
            CustLedgEntry.SetCurrentKey("Customer No.");
        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        CustLedgEntry.SetRange(Open, true);
        if not CustLedgEntry.IsEmpty then
            Error(
              Text001,
              Cust.TableCaption, Cust."No.");

        ReminderEntry.Reset();
        ReminderEntry.SetCurrentKey("Customer No.");
        ReminderEntry.SetRange("Customer No.", Cust."No.");
        ReminderEntry.ModifyAll("Customer No.", NewCustNo);

        CustLedgEntry.SetRange(Open);
        CustLedgEntry.ModifyAll("Customer No.", NewCustNo);

        ServLedgEntry.Reset();
        ServLedgEntry.SetRange("Customer No.", Cust."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              Cust.TableCaption, Cust."No.");

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              Cust.TableCaption, Cust."No.");

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("Customer No.", NewCustNo);

        ServLedgEntry.Reset();
        ServLedgEntry.SetRange("Bill-to Customer No.", Cust."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              Cust.TableCaption, Cust."No.");

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              Cust.TableCaption, Cust."No.");

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("Bill-to Customer No.", NewCustNo);

        WarrantyLedgEntry.LockTable();
        WarrantyLedgEntry.SetRange("Customer No.", Cust."No.");
        WarrantyLedgEntry.ModifyAll("Customer No.", NewCustNo);

        WarrantyLedgEntry.SetRange("Customer No.");
        WarrantyLedgEntry.SetRange("Bill-to Customer No.", Cust."No.");
        WarrantyLedgEntry.ModifyAll("Bill-to Customer No.", NewCustNo);

        ServContract.SetFilter(Status, '<>%1', ServContract.Status::Canceled);
        ServContract.SetRange("Customer No.", Cust."No.");
        if not ServContract.IsEmpty then
            Error(CannotDeleteBecauseServiceContractErr, Cust."No.");

        ServContract.SetRange(Status);
        ServContract.ModifyAll("Customer No.", NewCustNo);

        ServContract.Reset();
        ServContract.SetFilter(Status, '<>%1', ServContract.Status::Canceled);
        ServContract.SetRange("Bill-to Customer No.", Cust."No.");
        if not ServContract.IsEmpty then
            Error(CannotDeleteBecauseServiceContractErr, Cust."No.");

        ServContract.SetRange(Status);
        ServContract.ModifyAll("Bill-to Customer No.", NewCustNo);

        OnAfterMoveCustEntries(Cust, CustLedgEntry, ReminderEntry, ServLedgEntry, WarrantyLedgEntry);
    end;

    procedure MoveVendorEntries(Vend: Record Vendor)
    var
        NewVendNo: Code[20];
    begin
        OnBeforeMoveVendEntries(Vend, NewVendNo);

        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            VendLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not VendLedgEntry.IsEmpty then
            Error(
              Text000,
              Vend.TableCaption, Vend."No.");

        VendLedgEntry.Reset();
        if not VendLedgEntry.SetCurrentKey("Vendor No.", Open) then
            VendLedgEntry.SetCurrentKey("Vendor No.");
        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetRange(Open, true);
        if not VendLedgEntry.IsEmpty then
            Error(
              Text001,
              Vend.TableCaption, Vend."No.");

        VendLedgEntry.SetRange(Open);
        VendLedgEntry.ModifyAll("Vendor No.", NewVendNo);

        WarrantyLedgEntry.LockTable();
        WarrantyLedgEntry.SetRange("Vendor No.", Vend."No.");
        WarrantyLedgEntry.ModifyAll("Vendor No.", NewVendNo);

        ServiceItem.SetRange("Vendor No.", Vend."No.");
        if not ServiceItem.IsEmpty then
            ServiceItem.ModifyAll("Vendor No.", NewVendNo);

        OnAfterMoveVendorEntries(Vend, VendLedgEntry, WarrantyLedgEntry);
    end;

    procedure MoveBankAccEntries(BankAcc: Record "Bank Account")
    var
        NewBankAccNo: Code[20];
    begin
        OnBeforeMoveBankAccEntries(BankAcc, NewBankAccNo);

        BankAccLedgEntry.Reset();
        BankAccLedgEntry.SetCurrentKey("Bank Account No.", "Posting Date");
        BankAccLedgEntry.SetRange("Bank Account No.", BankAcc."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            BankAccLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not BankAccLedgEntry.IsEmpty then
            Error(
              Text000,
              BankAcc.TableCaption, BankAcc."No.");

        BankAccLedgEntry.Reset();
        if not BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open) then
            BankAccLedgEntry.SetCurrentKey("Bank Account No.");
        BankAccLedgEntry.SetRange("Bank Account No.", BankAcc."No.");
        BankAccLedgEntry.SetRange(Open, true);
        if not BankAccLedgEntry.IsEmpty then
            Error(
              Text001,
              BankAcc.TableCaption, BankAcc."No.");

        BankAccLedgEntry.SetRange(Open);
        BankAccLedgEntry.ModifyAll("Bank Account No.", '');
        CheckLedgEntry.SetCurrentKey("Bank Account No.");
        CheckLedgEntry.SetRange("Bank Account No.", BankAcc."No.");
        CheckLedgEntry.ModifyAll("Bank Account No.", NewBankAccNo);

        OnAfterMoveBankAccEntries(BankAcc, BankAccLedgEntry, CheckLedgEntry);
    end;

    procedure MoveItemEntries(Item: Record Item)
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        NewItemNo: Code[20];
    begin
        OnBeforeMoveItemEntries(Item, NewItemNo);

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ItemLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ItemLedgEntry.IsEmpty then begin
            if EnvInfoProxy.IsInvoicing then
                Error(
                  CannotDeleteBecauseInInvErr,
                  Item.TableCaption);

            Error(
              Text000,
              Item.TableCaption, Item."No.");
        end;

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange("Completely Invoiced", false);
        if not ItemLedgEntry.IsEmpty then
            Error(
              Text008 +
              Text003 +
              Text009, Item."No.");
        ItemLedgEntry.SetRange("Completely Invoiced");

        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange(Open, true);
        if not ItemLedgEntry.IsEmpty then
            Error(
              Text001,
              Item.TableCaption, Item."No.");

        ItemLedgEntry.SetCurrentKey("Item No.", "Applied Entry to Adjust");
        ItemLedgEntry.SetRange(Open, false);
        ItemLedgEntry.SetRange("Applied Entry to Adjust", true);
        if not ItemLedgEntry.IsEmpty then
            Error(
              Text002 +
              Text003 +
              Text004,
              Item."No.", Text005);
        ItemLedgEntry.SetRange("Applied Entry to Adjust");

        if Item."Costing Method" = Item."Costing Method"::Average then begin
            AvgCostAdjmt.Reset();
            AvgCostAdjmt.SetRange("Item No.", Item."No.");
            AvgCostAdjmt.SetRange("Cost Is Adjusted", false);
            if not AvgCostAdjmt.IsEmpty then
                Error(
                  Text002 +
                  Text003 +
                  Text004,
                  Item."No.", Text005);
        end;

        ItemLedgEntry.SetRange(Open);
        ItemLedgEntry.ModifyAll("Item No.", NewItemNo);

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.ModifyAll("Item No.", NewItemNo);

        AvgCostAdjmt.Reset();
        AvgCostAdjmt.SetRange("Item No.", Item."No.");
        AvgCostAdjmt.DeleteAll();

        InvtAdjmtEntryOrder.Reset();
        InvtAdjmtEntryOrder.SetRange("Item No.", Item."No.");
        InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Production);
        InvtAdjmtEntryOrder.ModifyAll("Cost is Adjusted", true);
        InvtAdjmtEntryOrder.SetRange("Order Type");
        InvtAdjmtEntryOrder.ModifyAll("Item No.", NewItemNo);

        ServLedgEntry.Reset();
        ServLedgEntry.SetRange("Item No. (Serviced)", Item."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              Item.TableCaption, Item."No.");

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              Item.TableCaption, Item."No.");

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("Item No. (Serviced)", NewItemNo);

        ServLedgEntry.SetRange("Item No. (Serviced)");
        ServLedgEntry.SetRange(Type, ServLedgEntry.Type::Item);
        ServLedgEntry.SetRange("No.", Item."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              Item.TableCaption, Item."No.");

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              Item.TableCaption, Item."No.");

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("No.", NewItemNo);

        WarrantyLedgEntry.LockTable();
        WarrantyLedgEntry.SetRange("Item No. (Serviced)", Item."No.");
        WarrantyLedgEntry.ModifyAll("Item No. (Serviced)", NewItemNo);

        WarrantyLedgEntry.SetRange("Item No. (Serviced)");
        WarrantyLedgEntry.SetRange(Type, WarrantyLedgEntry.Type::Item);
        WarrantyLedgEntry.SetRange("No.", Item."No.");
        WarrantyLedgEntry.ModifyAll("No.", NewItemNo);

        ServiceItem.Reset();
        ServiceItem.SetRange("Item No.", Item."No.");
        if not ServiceItem.IsEmpty then
            ServiceItem.ModifyAll("Item No.", NewItemNo, true);

        ServiceItemComponent.Reset();
        ServiceItemComponent.SetRange(Type, ServiceItemComponent.Type::Item);
        ServiceItemComponent.SetRange("No.", Item."No.");
        if not ServiceItemComponent.IsEmpty then
            ServiceItemComponent.ModifyAll("No.", NewItemNo);

        OnAfterMoveItemEntries(Item, ItemLedgEntry, ValueEntry, ServLedgEntry, WarrantyLedgEntry, InvtAdjmtEntryOrder);
    end;

    procedure MoveResEntries(Res: Record Resource)
    var
        NewResNo: Code[20];
    begin
        OnBeforeMoveResEntries(Res, NewResNo);

        ResLedgEntry.Reset();
        ResLedgEntry.SetCurrentKey("Resource No.", "Posting Date");
        ResLedgEntry.SetRange("Resource No.", Res."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ResLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ResLedgEntry.IsEmpty then
            Error(
              Text000,
              Res.TableCaption, Res."No.");

        ResLedgEntry.Reset();
        ResLedgEntry.SetCurrentKey("Resource No.");
        ResLedgEntry.SetRange("Resource No.", Res."No.");
        ResLedgEntry.ModifyAll("Resource No.", NewResNo);

        ServLedgEntry.Reset();
        ServLedgEntry.SetRange(Type, ServLedgEntry.Type::Resource);
        ServLedgEntry.SetRange("No.", Res."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              Res.TableCaption, Res."No.");

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              Res.TableCaption, Res."No.");

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("No.", NewResNo);

        WarrantyLedgEntry.LockTable();
        WarrantyLedgEntry.SetRange(Type, WarrantyLedgEntry.Type::Resource);
        WarrantyLedgEntry.SetRange("No.", Res."No.");
        WarrantyLedgEntry.ModifyAll("No.", NewResNo);

        OnAfterMoveResEntries(Res, ResLedgEntry, ServLedgEntry, WarrantyLedgEntry);
    end;

    procedure MoveJobEntries(Job: Record Job)
    var
        TimeSheetLine: Record "Time Sheet Line";
        NewJobNo: Code[20];
    begin
        OnBeforeMoveJobEntries(Job, NewJobNo);

        JobLedgEntry.SetCurrentKey("Job No.");
        JobLedgEntry.SetRange("Job No.", Job."No.");
        if not JobLedgEntry.IsEmpty then
            Error(
              Text006,
              Job.TableCaption, Job."No.");

        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.SetRange("Job No.", Job."No.");
        TimeSheetLine.SetFilter(Status, '%1|%2', TimeSheetLine.Status::Open, TimeSheetLine.Status::Submitted);
        if not TimeSheetLine.IsEmpty then
            Error(TimeSheetLinesErr, Job."No.");

        PurchOrderLine.SetCurrentKey("Document Type");
        PurchOrderLine.SetFilter(
          "Document Type", '%1|%2',
          PurchOrderLine."Document Type"::Order,
          PurchOrderLine."Document Type"::"Return Order");
        PurchOrderLine.SetRange("Job No.", Job."No.");
        if PurchOrderLine.FindFirst then begin
            if PurchOrderLine."Document Type" = PurchOrderLine."Document Type"::Order then
                Error(Text007, Job.TableCaption, Job."No.");
            if PurchOrderLine."Document Type" = PurchOrderLine."Document Type"::"Return Order" then
                Error(Text015, Job.TableCaption, Job."No.");
        end;

        ServLedgEntry.Reset();
        ServLedgEntry.SetRange("Job No.", Job."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              Job.TableCaption, Job."No.");

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              Job.TableCaption, Job."No.");

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("Job No.", NewJobNo);

        OnAfterMoveJobEntries(Job, JobLedgEntry, TimeSheetLine, ServLedgEntry);
    end;

    procedure MoveServiceItemLedgerEntries(ServiceItem: Record "Service Item")
    var
        ResultDescription: Text;
        NewServiceItemNo: Code[20];
    begin
        OnBeforeMoveServiceItemLedgerEntries(ServiceItem, NewServiceItemNo);

        ServLedgEntry.LockTable();

        ResultDescription := CheckIfServiceItemCanBeDeleted(ServLedgEntry, ServiceItem."No.");
        if ResultDescription <> '' then
            Error(ResultDescription);

        ServLedgEntry.ModifyAll("Service Item No. (Serviced)", NewServiceItemNo);

        WarrantyLedgEntry.LockTable();
        WarrantyLedgEntry.SetRange("Service Item No. (Serviced)", ServiceItem."No.");
        WarrantyLedgEntry.ModifyAll("Service Item No. (Serviced)", NewServiceItemNo);

        OnAfterMoveServiceItemLedgerEntries(ServiceItem);
    end;

    procedure MoveServContractLedgerEntries(ServiceContractHeader: Record "Service Contract Header")
    var
        NewContractNo: Code[20];
    begin
        OnBeforeMoveServContractLedgerEntries(ServiceContractHeader, NewContractNo);

        if ServiceContractHeader.Prepaid then begin
            ServLedgEntry.Reset();
            ServLedgEntry.SetCurrentKey(Type, "No.");
            ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Contract");
            ServLedgEntry.SetRange("No.", ServiceContractHeader."Contract No.");
            ServLedgEntry.SetRange(Prepaid, true);
            ServLedgEntry.SetRange("Moved from Prepaid Acc.", false);
            ServLedgEntry.SetRange(Open, false);
            if not ServLedgEntry.IsEmpty then
                Error(
                  Text013,
                  ServiceContractHeader.TableCaption, ServiceContractHeader."Contract No.", ServLedgEntry.TableCaption);
            ServLedgEntry.SetRange(Open, true);
            if not ServLedgEntry.IsEmpty then
                Error(
                  Text014,
                  ServiceContractHeader.TableCaption, ServiceContractHeader."Contract No.", ServLedgEntry.TableCaption);
        end;

        ServLedgEntry.Reset();
        ServLedgEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              ServiceContractHeader.TableCaption, ServiceContractHeader."Contract No.");

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              ServiceContractHeader.TableCaption, ServiceContractHeader."Contract No.");

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("Service Contract No.", NewContractNo);

        ServLedgEntry.SetRange("Service Contract No.");
        ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Contract");
        ServLedgEntry.SetRange("No.", ServiceContractHeader."Contract No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              ServiceContractHeader.TableCaption, ServiceContractHeader."Contract No.");

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              ServiceContractHeader.TableCaption, ServiceContractHeader."Contract No.");

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("No.", NewContractNo);

        WarrantyLedgEntry.LockTable();
        WarrantyLedgEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        WarrantyLedgEntry.ModifyAll("Service Contract No.", NewContractNo);

        OnAfterMoveServContractLedgerEntries(ServiceContractHeader);
    end;

    procedure MoveServiceCostLedgerEntries(ServiceCost: Record "Service Cost")
    var
        NewCostCode: Code[10];
    begin
        OnBeforeMoveServiceCostLedgerEntries(ServiceCost, NewCostCode);

        ServLedgEntry.Reset();
        ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Cost");
        ServLedgEntry.SetRange("No.", ServiceCost.Code);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServLedgEntry.IsEmpty then
            Error(
              Text000,
              ServiceCost.TableCaption, ServiceCost.Code);

        ServLedgEntry.SetRange("Posting Date");
        ServLedgEntry.SetRange(Open, true);
        if not ServLedgEntry.IsEmpty then
            Error(
              Text001,
              ServiceCost.TableCaption, ServiceCost.Code);

        ServLedgEntry.SetRange(Open);
        ServLedgEntry.ModifyAll("No.", NewCostCode);

        WarrantyLedgEntry.LockTable();
        WarrantyLedgEntry.SetRange(Type, WarrantyLedgEntry.Type::"Service Cost");
        WarrantyLedgEntry.SetRange("No.", ServiceCost.Code);
        WarrantyLedgEntry.ModifyAll("No.", NewCostCode);

        OnAfterMoveServiceCostLedgerEntries(ServiceCost);
    end;

    procedure MoveCashFlowEntries(CashFlowAccount: Record "Cash Flow Account")
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFSetup: Record "Cash Flow Setup";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        NewAccountNo: Code[20];
    begin
        OnBeforeMoveCashFlowEntries(CashFlowAccount, NewAccountNo);

        CashFlowAccount.LockTable();

        if CashFlowAccount."Account Type" = CashFlowAccount."Account Type"::Entry then begin
            CashFlowAccount.CalcFields(Amount);
            CashFlowAccount.TestField(Amount, 0);
        end;

        CFForecastEntry.Reset();
        CFForecastEntry.SetCurrentKey("Cash Flow Account No.");
        CFForecastEntry.SetRange("Cash Flow Account No.", CashFlowAccount."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            CFForecastEntry.SetFilter("Cash Flow Date", '>%1', AccountingPeriod."Starting Date");
        if not CFForecastEntry.IsEmpty then
            Error(
              Text000,
              CashFlowAccount.TableCaption, CashFlowAccount."No.");

        CFSetup.Get();
        if CFSetup."Receivables CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Receivables CF Account No.", '');

        if CFSetup."Payables CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Payables CF Account No.", '');

        if CFSetup."Sales Order CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Sales Order CF Account No.", '');

        if CFSetup."Purch. Order CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Purch. Order CF Account No.", '');

        if CFSetup."FA Budget CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("FA Budget CF Account No.", '');

        if CFSetup."FA Disposal CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("FA Disposal CF Account No.", '');

        if CFSetup."Service CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Service CF Account No.", '');

        CFWorksheetLine.Reset();
        CFWorksheetLine.SetRange("Cash Flow Account No.", CashFlowAccount."No.");
        CFWorksheetLine.ModifyAll("Cash Flow Account No.", '');

        CFForecastEntry.Reset();
        CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.");
        CFForecastEntry.SetRange("Cash Flow Account No.", CashFlowAccount."No.");
        CFForecastEntry.ModifyAll("Cash Flow Account No.", '');

        OnAfterMoveCashFlowEntries(CashFlowAccount);
    end;

    procedure MoveDocRelatedEntries(TableNo: Integer; DocNo: Code[20])
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ValueEntry2: Record "Value Entry";
        CostCalcMgt: Codeunit "Cost Calculation Management";
    begin
        OnBeforeMoveDocRelatedEntries(TableNo, DocNo);

        ItemLedgEntry2.LockTable();
        ItemLedgEntry2.SetCurrentKey("Document No.");
        ItemLedgEntry2.SetRange("Document No.", DocNo);
        ItemLedgEntry2.SetRange("Document Type", CostCalcMgt.GetDocType(TableNo));
        ItemLedgEntry2.SetFilter("Document Line No.", '<>0');
        ItemLedgEntry2.ModifyAll("Document Line No.", 0);

        ValueEntry2.LockTable();
        ValueEntry2.SetCurrentKey("Document No.");
        ValueEntry2.SetRange("Document No.", DocNo);
        ValueEntry2.SetRange("Document Type", CostCalcMgt.GetDocType(TableNo));
        ValueEntry2.SetFilter("Document Line No.", '<>0');
        ValueEntry2.ModifyAll("Document Line No.", 0);

        OnAfterMoveDocRelatedEntries(TableNo, DocNo);
    end;

    procedure CheckIfServiceItemCanBeDeleted(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceItemNo: Code[20]): Text
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetCurrentKey("Service Item No. (Serviced)");
        ServiceLedgerEntry.SetRange("Service Item No. (Serviced)", ServiceItemNo);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty then
            exit(StrSubstNo(Text000, ServiceItem.TableCaption, ServiceItemNo));

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty then
            exit(StrSubstNo(Text001, ServiceItem.TableCaption, ServiceItemNo));

        ServiceLedgerEntry.SetRange(Open);
        exit('');
    end;

    local procedure CheckGLAccountEntries(GLAccount: Record "G/L Account"; GeneralLedgerSetup: Record "General Ledger Setup")
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        HasGLEntries: Boolean;
        HasGLBudgetEntries: Boolean;
    begin
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then begin
            GLAccount.CalcFields(Balance);
            GLAccount.TestField(Balance, 0);
        end;

        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst then
            GLEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not GLEntry.IsEmpty then
            Error(CannotDeleteGLAccountWithEntriesInOpenFiscalYearErr, GLAccount."No.");

        AccountingPeriod.SetRange(Closed, true);
        if AccountingPeriod.IsEmpty then
            exit;

        GeneralLedgerSetup.TestField("Allow G/L Acc. Deletion Before");

        GLEntry.SetFilter("Posting Date", '>=%1', GeneralLedgerSetup."Allow G/L Acc. Deletion Before");

        GLBudgetEntry.LockTable();
        GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Date);
        GLBudgetEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLBudgetEntry.SetFilter(Date, '>=%1', GeneralLedgerSetup."Allow G/L Acc. Deletion Before");

        HasGLEntries := not GLEntry.IsEmpty;
        HasGLBudgetEntries := GLBudgetEntry.FindFirst;

        if HasGLEntries or HasGLBudgetEntries then begin
            if ConfirmManagement.GetResponseOrDefault(GLAccDeleteClosedPeriodsQst, true) then
                exit;

            if HasGLEntries then
                Error(
                  CannotDeleteGLAccountWithEntriesAfterDateErr,
                  GLAccount."No.", GeneralLedgerSetup."Allow G/L Acc. Deletion Before");
            if HasGLBudgetEntries then
                Error(
                  CannotDeleteGLBudgetEntriesErr,
                  GLAccount."No.", GeneralLedgerSetup."Allow G/L Acc. Deletion Before", GLBudgetEntry."Budget Name");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveGLEntries(GLAccount: Record "G/L Account"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveCustEntries(Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; var ServiceLedgerEntry: Record "Service Ledger Entry"; var WarrantyLedgerEntry: Record "Warranty Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveVendorEntries(Vendor: Record Vendor; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var WarrantyLedgerEntry: Record "Warranty Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveBankAccEntries(BankAccount: Record "Bank Account"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveItemEntries(Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; var ServiceLedgerEntry: Record "Service Ledger Entry"; var WarrantyLedgerEntry: Record "Warranty Ledger Entry"; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveResEntries(Resource: Record Resource; var ResLedgerEntry: Record "Res. Ledger Entry"; var ServiceLedgerEntry: Record "Service Ledger Entry"; var WarrantyLedgerEntry: Record "Warranty Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveJobEntries(Job: Record Job; var JobLedgerEntry: Record "Job Ledger Entry"; var TimeSheetLine: Record "Time Sheet Line"; var ServiceLedgerEntry: Record "Service Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServiceItemLedgerEntries(ServiceItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServContractLedgerEntries(ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServiceCostLedgerEntries(ServiceCost: Record "Service Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveCashFlowEntries(CashFlowAccount: Record "Cash Flow Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveDocRelatedEntries(TableNo: Integer; DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveGLEntries(GLAccount: Record "G/L Account"; var GLAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveCustEntries(Customer: Record Customer; var NewCustNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveVendEntries(Vendor: Record Vendor; var NewVendNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveBankAccEntries(BankAccount: Record "Bank Account"; var NewBankAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveItemEntries(Item: Record Item; var NewItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveResEntries(Resource: Record Resource; var NewResNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveJobEntries(Job: Record Job; var NewJobNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServiceItemLedgerEntries(ServiceItem: Record "Service Item"; var NewServiceItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServContractLedgerEntries(ServiceContractHeader: Record "Service Contract Header"; var NewContractNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServiceCostLedgerEntries(ServiceCost: Record "Service Cost"; var NewCostCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveCashFlowEntries(CashFlowAccount: Record "Cash Flow Account"; var NewAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveDocRelatedEntries(TableNo: Integer; DocNo: Code[20])
    begin
    end;
}

