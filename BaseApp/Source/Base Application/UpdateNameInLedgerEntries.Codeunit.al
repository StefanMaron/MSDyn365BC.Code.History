codeunit 104 "Update Name In Ledger Entries"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Item Ledger Entry" = rm,
                  TableData "Phys. Inventory Ledger Entry" = rm,
                  TableData "Value Entry" = rm;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        Update("Parameter String");
    end;

    var
        JobQueueDescrTxt: Label 'Update %1 name in %1 ledger entries.', Comment = '%1 - text: Customer or Vendor';
        ParameterNotSupportedErr: Label 'The Parameter String field must contain ''Customer'',''Vendor'', or ''Item''. The current value ''%1'' is not supported.', Comment = '%1 - any text value';
        CustomerNamesUpdateMsg: Label '%1 customer ledger entries with empty Customer Name field were found. Do you want to update these entries by inserting the name from the customer cards?', Comment = '%1 = number of entries';
        VendorNamesUpdateMsg: Label '%1 vendor ledger entries with empty Vendor Name field were found. Do you want to update these entries by inserting the name from the vendor cards?', Comment = '%1 = number of entries';
        ItemDescriptionUpdateMsg: Label '%1 ledger entries with empty Description field were found. Do you want to update these entries by inserting the description from the item cards?', Comment = '%1 = number of entries';
        ScheduleUpdateMsg: Label 'Schedule update';

    procedure ScheduleUpdate(Notification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduleAJob: Page "Schedule a Job";
    begin
        InsertJobQueueEntry(JobQueueEntry, Notification.GetData('Type'));
        ScheduleAJob.SetJob(JobQueueEntry);
        Commit();
        ScheduleAJob.RunModal;
    end;

    local procedure InsertJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; Type: Text)
    begin
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := StrSubstNo(JobQueueDescrTxt, LowerCase(Type));
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Update Name In Ledger Entries";
        JobQueueEntry."Parameter String" := CopyStr(Type, 1, MaxStrLen(JobQueueEntry."Parameter String"));
    end;

    procedure NotifyAboutBlankNamesInLedgerEntries(SetupRecordID: RecordID)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
        Counter: Integer;
    begin
        Counter := CountEntriesWithBlankName(SetupRecordID.TableNo);
        if Counter = 0 then
            exit;
        case SetupRecordID.TableNo of
            DATABASE::"Sales & Receivables Setup":
                begin
                    Notification.Message(StrSubstNo(CustomerNamesUpdateMsg, Counter));
                    Notification.SetData('Type', 'Customer');
                end;
            DATABASE::"Purchases & Payables Setup":
                begin
                    Notification.Message(StrSubstNo(VendorNamesUpdateMsg, Counter));
                    Notification.SetData('Type', 'Vendor');
                end;
            DATABASE::"Inventory Setup":
                begin
                    Notification.Message(StrSubstNo(ItemDescriptionUpdateMsg, Counter));
                    Notification.SetData('Type', 'Item');
                end;
        end;
        Notification.AddAction(ScheduleUpdateMsg, CODEUNIT::"Update Name In Ledger Entries", 'ScheduleUpdate');
        NotificationLifecycleMgt.SendNotification(Notification, SetupRecordID);
    end;

    local procedure CountEntriesWithBlankName(SetupTableNo: Integer): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        case SetupTableNo of
            DATABASE::"Sales & Receivables Setup":
                exit(
                  CountRecordsWithBlankField(
                    DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Customer No."),
                    CustLedgerEntry.FieldNo("Customer Name")));
            DATABASE::"Purchases & Payables Setup":
                exit(
                  CountRecordsWithBlankField(
                    DATABASE::"Vendor Ledger Entry", VendLedgerEntry.FieldNo("Vendor No."),
                    VendLedgerEntry.FieldNo("Vendor Name")));
            DATABASE::"Inventory Setup":
                exit(
                  CountRecordsWithBlankField(
                    DATABASE::"Item Ledger Entry", ItemLedgerEntry.FieldNo("Item No."),
                    ItemLedgerEntry.FieldNo(Description)) +
                  CountRecordsWithBlankField(
                    DATABASE::"Value Entry", ValueEntry.FieldNo("Item No."),
                    ValueEntry.FieldNo(Description)) +
                  CountRecordsWithBlankField(
                    DATABASE::"Phys. Inventory Ledger Entry", PhysInventoryLedgerEntry.FieldNo("Item No."),
                    PhysInventoryLedgerEntry.FieldNo(Description)));
        end
    end;

    local procedure CountRecordsWithBlankField(TableNo: Integer; MasterFieldNo: Integer; FieldNo: Integer) Result: Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(MasterFieldNo);
        FieldRef.SetFilter(StrSubstNo('<>'''''));
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.SetRange('');
        if RecRef.IsEmpty then
            Result := 0;
        Result := RecRef.Count();
        RecRef.Close;
    end;

    local procedure GetCustomer(CustomerNo: Code[20]; var Customer: Record Customer): Boolean
    begin
        if Customer."No." = CustomerNo then
            exit(true);
        exit(Customer.Get(CustomerNo));
    end;

    local procedure GetItem(ItemNo: Code[20]; var Item: Record Item): Boolean
    begin
        if Item."No." = ItemNo then
            exit(true);
        exit(Item.Get(ItemNo));
    end;

    local procedure GetItemVariant(ItemNo: Code[20]; VariantCode: Code[10]; var ItemVariant: Record "Item Variant"): Boolean
    begin
        if VariantCode = '' then
            exit(false);
        if (ItemVariant."Item No." = ItemNo) and (ItemVariant.Code = VariantCode) then
            exit(true);
        exit(ItemVariant.Get(ItemNo, VariantCode));
    end;

    local procedure GetVendor(VendorNo: Code[20]; var Vendor: Record Vendor): Boolean
    begin
        if Vendor."No." = VendorNo then
            exit(true);
        exit(Vendor.Get(VendorNo));
    end;

    local procedure Update(Param: Text)
    begin
        case LowerCase(Param) of
            'customer':
                UpdateCustNamesInLedgerEntries;
            'item':
                UpdateItemDescrInLedgerEntries;
            'vendor':
                UpdateVendNamesInLedgerEntries;
            else
                Error(StrSubstNo(ParameterNotSupportedErr, Param));
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCustNamesInLedgerEntries()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgEntry do begin
            Reset;
            SetFilter("Customer No.", '<>''''');
            SetRange("Customer Name", '');
            if FindSet(true, false) then
                repeat
                    if GetCustomer("Customer No.", Customer) then begin
                        "Customer Name" := Customer.Name;
                        Modify;
                    end;
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateItemDescrInLedgerEntries()
    begin
        UpdateItemDescrInItemLedgerEntries;
        UpdateItemDescrInValueEntries;
        UpdateItemDescrInPhysInvLedgerEntries;
    end;

    local procedure UpdateItemDescrInItemLedgerEntries()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do begin
            Reset;
            SetFilter("Item No.", '<>''''');
            SetRange(Description, '');
            if FindSet(true, false) then
                repeat
                    if GetItem("Item No.", Item) then begin
                        Description := Item.Description;
                        if GetItemVariant("Item No.", "Variant Code", ItemVariant) then
                            Description := ItemVariant.Description;
                        Modify;
                    end;
                until Next = 0;
        end;
    end;

    local procedure UpdateItemDescrInPhysInvLedgerEntries()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        with PhysInventoryLedgerEntry do begin
            Reset;
            SetFilter("Item No.", '<>''''');
            SetRange(Description, '');
            if FindSet(true, false) then
                repeat
                    if GetItem("Item No.", Item) then begin
                        Description := Item.Description;
                        if GetItemVariant("Item No.", "Variant Code", ItemVariant) then
                            Description := ItemVariant.Description;
                        Modify;
                    end;
                until Next = 0;
        end;
    end;

    local procedure UpdateItemDescrInValueEntries()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            Reset;
            SetFilter("Item No.", '<>''''');
            SetRange(Description, '');
            if FindSet(true, false) then
                repeat
                    if GetItem("Item No.", Item) then begin
                        Description := Item.Description;
                        if GetItemVariant("Item No.", "Variant Code", ItemVariant) then
                            Description := ItemVariant.Description;
                        Modify;
                    end;
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateVendNamesInLedgerEntries()
    var
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            Reset;
            SetFilter("Vendor No.", '<>''''');
            SetRange("Vendor Name", '');
            if FindSet(true, false) then
                repeat
                    if GetVendor("Vendor No.", Vendor) then begin
                        "Vendor Name" := Vendor.Name;
                        Modify;
                    end;
                until Next = 0;
        end;
    end;
}

