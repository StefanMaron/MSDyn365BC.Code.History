codeunit 46 SelectionFilterManagement
{

    trigger OnRun()
    begin
    end;

    procedure GetSelectionFilter(var TempRecRef: RecordRef; SelectionFieldID: Integer): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FirstRecRef: Text;
        LastRecRef: Text;
        SelectionFilter: Text;
        SavePos: Text;
        TempRecRefCount: Integer;
        More: Boolean;
    begin
        if TempRecRef.IsTemporary then begin
            RecRef := TempRecRef.Duplicate;
            RecRef.Reset();
        end else
            RecRef.Open(TempRecRef.Number);

        TempRecRefCount := TempRecRef.Count();
        if TempRecRefCount > 0 then begin
            TempRecRef.Ascending(true);
            TempRecRef.Find('-');
            while TempRecRefCount > 0 do begin
                TempRecRefCount := TempRecRefCount - 1;
                RecRef.SetPosition(TempRecRef.GetPosition);
                RecRef.Find;
                FieldRef := RecRef.Field(SelectionFieldID);
                FirstRecRef := Format(FieldRef.Value);
                LastRecRef := FirstRecRef;
                More := TempRecRefCount > 0;
                while More do
                    if RecRef.Next = 0 then
                        More := false
                    else begin
                        SavePos := TempRecRef.GetPosition;
                        TempRecRef.SetPosition(RecRef.GetPosition);
                        if not TempRecRef.Find then begin
                            More := false;
                            TempRecRef.SetPosition(SavePos);
                        end else begin
                            FieldRef := RecRef.Field(SelectionFieldID);
                            LastRecRef := Format(FieldRef.Value);
                            TempRecRefCount := TempRecRefCount - 1;
                            if TempRecRefCount = 0 then
                                More := false;
                        end;
                    end;
                if SelectionFilter <> '' then
                    SelectionFilter := SelectionFilter + '|';
                if FirstRecRef = LastRecRef then
                    SelectionFilter := SelectionFilter + AddQuotes(FirstRecRef)
                else
                    SelectionFilter := SelectionFilter + AddQuotes(FirstRecRef) + '..' + AddQuotes(LastRecRef);
                if TempRecRefCount > 0 then
                    TempRecRef.Next;
            end;
            exit(SelectionFilter);
        end;
    end;

    procedure AddQuotes(inString: Text[1024]): Text
    begin
        if DelChr(inString, '=', ' &|()*@<>=.') = inString then
            exit(inString);
        exit('''' + inString + '''');
    end;

    procedure GetSelectionFilterForItem(var Item: Record Item): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Item);
        exit(GetSelectionFilter(RecRef, Item.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForDimensionValue(var DimVal: Record "Dimension Value"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DimVal);
        exit(GetSelectionFilter(RecRef, DimVal.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCurrency(var Currency: Record Currency): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Currency);
        exit(GetSelectionFilter(RecRef, Currency.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCustomerPriceGroup(var CustomerPriceGroup: Record "Customer Price Group"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustomerPriceGroup);
        exit(GetSelectionFilter(RecRef, CustomerPriceGroup.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForLocation(var Location: Record Location): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Location);
        exit(GetSelectionFilter(RecRef, Location.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForGLAccount(var GLAccount: Record "G/L Account"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GLAccount);
        exit(GetSelectionFilter(RecRef, GLAccount.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForCustomer(var Customer: Record Customer): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Customer);
        exit(GetSelectionFilter(RecRef, Customer.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForContact(var Contact: Record Contact): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Contact);
        exit(GetSelectionFilter(RecRef, Contact.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForVendor(var Vendor: Record Vendor): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Vendor);
        exit(GetSelectionFilter(RecRef, Vendor.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForResource(var Resource: Record Resource): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Resource);
        exit(GetSelectionFilter(RecRef, Resource.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForInventoryPostingGroup(var InventoryPostingGroup: Record "Inventory Posting Group"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(InventoryPostingGroup);
        exit(GetSelectionFilter(RecRef, InventoryPostingGroup.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForGLBudgetName(var GLBudgetName: Record "G/L Budget Name"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GLBudgetName);
        exit(GetSelectionFilter(RecRef, GLBudgetName.FieldNo(Name)));
    end;

    procedure GetSelectionFilterForBusinessUnit(var BusinessUnit: Record "Business Unit"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(BusinessUnit);
        exit(GetSelectionFilter(RecRef, BusinessUnit.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForICPartner(var ICPartner: Record "IC Partner"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ICPartner);
        exit(GetSelectionFilter(RecRef, ICPartner.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCashFlow(var CashFlowForecast: Record "Cash Flow Forecast"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CashFlowForecast);
        exit(GetSelectionFilter(RecRef, CashFlowForecast.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForCashFlowAccount(var CashFlowAccount: Record "Cash Flow Account"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CashFlowAccount);
        exit(GetSelectionFilter(RecRef, CashFlowAccount.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForCostBudgetName(var CostBudgetName: Record "Cost Budget Name"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CostBudgetName);
        exit(GetSelectionFilter(RecRef, CostBudgetName.FieldNo(Name)));
    end;

    procedure GetSelectionFilterForCostCenter(var CostCenter: Record "Cost Center"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CostCenter);
        exit(GetSelectionFilter(RecRef, CostCenter.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCostObject(var CostObject: Record "Cost Object"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CostObject);
        exit(GetSelectionFilter(RecRef, CostObject.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForCostType(var CostType: Record "Cost Type"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CostType);
        exit(GetSelectionFilter(RecRef, CostType.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForCampaign(var Campaign: Record Campaign): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Campaign);
        exit(GetSelectionFilter(RecRef, Campaign.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForLotNoInformation(var LotNoInformation: Record "Lot No. Information"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(LotNoInformation);
        exit(GetSelectionFilter(RecRef, LotNoInformation.FieldNo("Lot No.")));
    end;

    procedure GetSelectionFilterForSerialNoInformation(var SerialNoInformation: Record "Serial No. Information"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SerialNoInformation);
        exit(GetSelectionFilter(RecRef, SerialNoInformation.FieldNo("Serial No.")));
    end;

    procedure GetSelectionFilterForCustomerDiscountGroup(var CustomerDiscountGroup: Record "Customer Discount Group"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustomerDiscountGroup);
        exit(GetSelectionFilter(RecRef, CustomerDiscountGroup.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForItemDiscountGroup(var ItemDiscountGroup: Record "Item Discount Group"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ItemDiscountGroup);
        exit(GetSelectionFilter(RecRef, ItemDiscountGroup.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForItemCategory(var ItemCategory: Record "Item Category"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ItemCategory);
        exit(GetSelectionFilter(RecRef, ItemCategory.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForIssueReminder(var ReminderHeader: Record "Reminder Header"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ReminderHeader);
        exit(GetSelectionFilter(RecRef, ReminderHeader.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WorkflowStepInstance);
        exit(GetSelectionFilter(RecRef, WorkflowStepInstance.FieldNo("Original Workflow Step ID")));
    end;

    procedure GetSelectionFilterForWorkflowBuffer(var TempWorkflowBuffer: Record "Workflow Buffer" temporary): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempWorkflowBuffer);
        exit(GetSelectionFilter(RecRef, TempWorkflowBuffer.FieldNo("Workflow Code")));
    end;

    procedure GetSelectionFilterForResponsibilityCenter(var ResponsibilityCenter: Record "Responsibility Center"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ResponsibilityCenter);
        exit(GetSelectionFilter(RecRef, ResponsibilityCenter.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForSalesPersonPurchaser(var SalespersonPurchaser: Record "Salesperson/Purchaser"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalespersonPurchaser);
        exit(GetSelectionFilter(RecRef, SalespersonPurchaser.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForItemVariant(var ItemVariant: Record "Item Variant"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ItemVariant);
        exit(GetSelectionFilter(RecRef, ItemVariant.FieldNo(Code)));
    end;

    procedure GetSelectionFilterForFixedAsset(var FixedAsset: Record "Fixed Asset"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(FixedAsset);
        exit(GetSelectionFilter(RecRef, FixedAsset.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForSalesHeader(var SalesHeader: Record "Sales Header"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesHeader);
        exit(GetSelectionFilter(RecRef, SalesHeader.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForPurchaseHeader(var PurchaseHeader: Record "Purchase Header"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PurchaseHeader);
        exit(GetSelectionFilter(RecRef, PurchaseHeader.FieldNo("No.")));
    end;

    procedure GetSelectionFilterForAggregatePermissionSetRoleId(var AggregatePermissionSet: Record "Aggregate Permission Set"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(AggregatePermissionSet);
        exit(GetSelectionFilter(RecRef, AggregatePermissionSet.FieldNo("Role ID")));
    end;
}

