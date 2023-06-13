codeunit 8616 "Config. Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempFieldRec: Record "Field" temporary;
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        HideDialog: Boolean;

        Text000: Label 'You must specify a company name.';
        Text001: Label 'Do you want to copy the data from the %1 table in %2?';
        Text002: Label 'Data from the %1 table in %2 has been copied successfully.';
        Text003: Label 'Do you want to copy the data from the selected tables in %1?';
        Text004: Label 'Data from the selected tables in %1 has been copied successfully.';
        Text006: Label 'The base company must not be the same as the current company.';
        Text007: Label 'The %1 table in %2 already contains data.\\You must delete the data from the table before you can use this function.';
        Text009: Label 'There is no data in the %1 table in %2.\\You must set up the table in %3 manually.';
        Text023: Label 'Processing tables';

    procedure CopyDataDialog(NewCompanyName: Text[30]; var ConfigLine: Record "Config. Line")
    var
        ConfirmTableText: Text[250];
        MessageTableText: Text[250];
        SingleTable: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDataDialog(ConfigLine, NewCompanyName, IsHandled);
        if IsHandled then
            exit;

        with ConfigLine do begin
            if NewCompanyName = '' then
                Error(Text000);
            if not FindFirst() then
                exit;
            SingleTable := Next() = 0;
            if SingleTable then begin
                ConfirmTableText := StrSubstNo(Text001, Name, NewCompanyName);
                MessageTableText := StrSubstNo(Text002, Name, NewCompanyName);
            end else begin
                ConfirmTableText := StrSubstNo(Text003, NewCompanyName);
                MessageTableText := StrSubstNo(Text004, NewCompanyName);
            end;
            if not Confirm(ConfirmTableText, SingleTable) then
                exit;
            if FindSet() then
                repeat
                    CopyData(ConfigLine);
                until Next() = 0;
            Commit();
            Message(MessageTableText)
        end;
    end;

    local procedure CopyData(var ConfigLine: Record "Config. Line")
    var
        BaseCompanyName: Text[30];
    begin
        with ConfigLine do begin
            CheckBlocked();
            FilterGroup := 2;
            BaseCompanyName := GetRangeMax("Company Filter (Source Table)");
            FilterGroup := 0;
            if BaseCompanyName = CompanyName then
                Error(Text006);
            CalcFields("No. of Records", "No. of Records (Source Table)");
            if "No. of Records" <> 0 then
                Error(
                  Text007,
                  Name, CompanyName);
            if "No. of Records (Source Table)" = 0 then
                Error(
                  Text009,
                  Name, BaseCompanyName, CompanyName);
            TransferContents("Table ID", BaseCompanyName, true);
        end;
    end;

    procedure TransferContents(TableID: Integer; NewCompanyName: Text[30]; CopyTable: Boolean): Boolean
    begin
        TempFieldRec.DeleteAll();
        if CopyTable then
            MarkPostValidationData(DATABASE::Contact, 5053);
        TransferContent(TableID, NewCompanyName, CopyTable);
        TempFieldRec.DeleteAll();
        exit(true);
    end;

    local procedure TransferContent(TableNumber: Integer; NewCompanyName: Text[30]; CopyTable: Boolean)
    var
        FieldRec: Record "Field";
        FromCompanyRecRef: RecordRef;
        ToCompanyRecRef: RecordRef;
        FromCompanyFieldRef: FieldRef;
        ToCompanyFieldRef: FieldRef;
    begin
        if not CopyTable then
            exit;
        FromCompanyRecRef.Open(TableNumber, false, NewCompanyName);
        if FromCompanyRecRef.IsEmpty() then begin
            FromCompanyRecRef.Close();
            exit;
        end;
        FromCompanyRecRef.Find('-');
        ToCompanyRecRef.Open(TableNumber, false, CompanyName);
        FieldRec.SetRange(TableNo, TableNumber);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        repeat
            if FieldRec.FindSet() then begin
                ToCompanyRecRef.Init();
                repeat
                    if not TempFieldRec.Get(TableNumber, FieldRec."No.") then begin
                        FromCompanyFieldRef := FromCompanyRecRef.Field(FieldRec."No.");
                        ToCompanyFieldRef := ToCompanyRecRef.Field(FieldRec."No.");
                        OnTransferContentOnBeforeToCompanyFieldRefValue(FieldRec, FromCompanyFieldRef);
                        ToCompanyFieldRef.Value(FromCompanyFieldRef.Value);
                    end;
                until FieldRec.Next() = 0;
                ToCompanyRecRef.Insert(true);
            end;
        until FromCompanyRecRef.Next() = 0;
        // Treatment of fields that require post-validation:
        TempFieldRec.SetRange(TableNo, TableNumber);
        TempFieldRec.SetRange(ObsoleteState, TempFieldRec.ObsoleteState::No);
        if TempFieldRec.FindSet() then begin
            FromCompanyRecRef.Find('-');
            repeat
                ToCompanyRecRef.SetPosition(FromCompanyRecRef.GetPosition());
                ToCompanyRecRef.Find('=');
                TempFieldRec.FindSet();
                repeat
                    FromCompanyFieldRef := FromCompanyRecRef.Field(TempFieldRec."No.");
                    ToCompanyFieldRef := ToCompanyRecRef.Field(TempFieldRec."No.");
                    ToCompanyFieldRef.Value(FromCompanyFieldRef.Value);
                until TempFieldRec.Next() = 0;
                ToCompanyRecRef.Modify(true);
            until FromCompanyRecRef.Next() = 0;
        end;

        FromCompanyRecRef.Close();
        ToCompanyRecRef.Close();
    end;

    local procedure MarkPostValidationData(TableNo: Integer; FieldNo: Integer)
    begin
        TempFieldRec.Init();
        TempFieldRec.TableNo := TableNo;
        TempFieldRec."No." := FieldNo;
        if TempFieldRec.Insert() then;
    end;

    procedure FindPage(TableID: Integer): Integer
    var
        PageID: Integer;
    begin
        case TableID of
            DATABASE::"Company Information":
                exit(PAGE::"Company Information");
            DATABASE::"Responsibility Center":
                exit(PAGE::"Responsibility Center List");
            DATABASE::"Accounting Period":
                exit(PAGE::"Accounting Periods");
            DATABASE::"General Ledger Setup":
                exit(PAGE::"General Ledger Setup");
            DATABASE::"No. Series":
                exit(PAGE::"No. Series");
            DATABASE::"No. Series Line":
                exit(PAGE::"No. Series Lines");
            DATABASE::"G/L Account":
                exit(PAGE::"Chart of Accounts");
            DATABASE::"Gen. Business Posting Group":
                exit(PAGE::"Gen. Business Posting Groups");
            DATABASE::"Gen. Product Posting Group":
                exit(PAGE::"Gen. Product Posting Groups");
            DATABASE::"General Posting Setup":
                exit(PAGE::"General Posting Setup");
            DATABASE::"VAT Business Posting Group":
                exit(PAGE::"VAT Business Posting Groups");
            DATABASE::"VAT Product Posting Group":
                exit(PAGE::"VAT Product Posting Groups");
            DATABASE::"VAT Posting Setup":
                exit(PAGE::"VAT Posting Setup");
            DATABASE::"Acc. Schedule Name":
                exit(PAGE::"Account Schedule Names");
            DATABASE::"Column Layout Name":
                exit(PAGE::"Column Layout Names");
            DATABASE::"G/L Budget Name":
                exit(PAGE::"G/L Budget Names");
            DATABASE::"VAT Statement Template":
                exit(PAGE::"VAT Statement Templates");
            DATABASE::"Tariff Number":
                exit(PAGE::"Tariff Numbers");
            DATABASE::"Transaction Type":
                exit(PAGE::"Transaction Types");
            DATABASE::"Transaction Specification":
                exit(PAGE::"Transaction Specifications");
            DATABASE::"Transport Method":
                exit(PAGE::"Transport Methods");
            DATABASE::"Entry/Exit Point":
                exit(PAGE::"Entry/Exit Points");
            DATABASE::Area:
                exit(PAGE::Areas);
            DATABASE::Territory:
                exit(PAGE::Territories);
            DATABASE::"Tax Jurisdiction":
                exit(PAGE::"Tax Jurisdictions");
            DATABASE::"Tax Group":
                exit(PAGE::"Tax Groups");
            DATABASE::"Tax Detail":
                exit(PAGE::"Tax Details");
            DATABASE::"Tax Area":
                exit(PAGE::"Tax Area");
            DATABASE::"Tax Area Line":
                exit(PAGE::"Tax Area Line");
            DATABASE::"Source Code":
                exit(PAGE::"Source Codes");
            DATABASE::"Reason Code":
                exit(PAGE::"Reason Codes");
            DATABASE::"Standard Text":
                exit(PAGE::"Standard Text Codes");
            DATABASE::"Business Unit":
                exit(PAGE::"Business Unit List");
            DATABASE::Dimension:
                exit(PAGE::Dimensions);
            DATABASE::"Default Dimension Priority":
                exit(PAGE::"Default Dimension Priorities");
            DATABASE::"Dimension Combination":
                exit(PAGE::"Dimension Combinations");
            DATABASE::"Analysis View":
                exit(PAGE::"Analysis View List");
            DATABASE::"Post Code":
                exit(PAGE::"Post Codes");
            DATABASE::"Country/Region":
                exit(PAGE::"Countries/Regions");
            DATABASE::Language:
                exit(PAGE::Languages);
            DATABASE::Currency:
                exit(PAGE::Currencies);
            DATABASE::"Bank Account":
                exit(PAGE::"Bank Account List");
            DATABASE::"Bank Account Posting Group":
                exit(PAGE::"Bank Account Posting Groups");
            DATABASE::"Change Log Setup (Table)":
                exit(PAGE::"Change Log Setup (Table) List");
            DATABASE::"Change Log Setup (Field)":
                exit(PAGE::"Change Log Setup (Field) List");
            DATABASE::"Sales & Receivables Setup":
                exit(PAGE::"Sales & Receivables Setup");
            DATABASE::Customer:
                exit(PAGE::"Customer List");
            DATABASE::"Customer Posting Group":
                exit(PAGE::"Customer Posting Groups");
            DATABASE::"Payment Terms":
                exit(PAGE::"Payment Terms");
            DATABASE::"Payment Method":
                exit(PAGE::"Payment Methods");
            DATABASE::"Reminder Terms":
                exit(PAGE::"Reminder Terms");
            DATABASE::"Reminder Level":
                exit(PAGE::"Reminder Levels");
            DATABASE::"Reminder Text":
                exit(PAGE::"Reminder Text");
            DATABASE::"Finance Charge Terms":
                exit(PAGE::"Finance Charge Terms");
            DATABASE::"Shipment Method":
                exit(PAGE::"Shipment Methods");
            DATABASE::"Shipping Agent":
                exit(PAGE::"Shipping Agents");
            DATABASE::"Shipping Agent Services":
                exit(PAGE::"Shipping Agent Services");
            DATABASE::"Customer Discount Group":
                exit(PAGE::"Customer Disc. Groups");
            DATABASE::"Salesperson/Purchaser":
                exit(PAGE::"Salespersons/Purchasers");
            DATABASE::"Marketing Setup":
                exit(PAGE::"Marketing Setup");
            DATABASE::"Duplicate Search String Setup":
                exit(PAGE::"Duplicate Search String Setup");
            DATABASE::Contact:
                exit(PAGE::"Contact List");
            DATABASE::"Business Relation":
                exit(PAGE::"Business Relations");
            DATABASE::"Mailing Group":
                exit(PAGE::"Mailing Groups");
            DATABASE::"Industry Group":
                exit(PAGE::"Industry Groups");
            DATABASE::"Web Source":
                exit(PAGE::"Web Sources");
            DATABASE::"Interaction Group":
                exit(PAGE::"Interaction Groups");
            DATABASE::"Interaction Template":
                exit(PAGE::"Interaction Templates");
            DATABASE::"Job Responsibility":
                exit(PAGE::"Job Responsibilities");
            DATABASE::"Organizational Level":
                exit(PAGE::"Organizational Levels");
            DATABASE::"Campaign Status":
                exit(PAGE::"Campaign Status");
            DATABASE::Activity:
                exit(PAGE::Activity);
            DATABASE::Team:
                exit(PAGE::Teams);
            DATABASE::"Profile Questionnaire Header":
                exit(PAGE::"Profile Questionnaires");
            DATABASE::"Sales Cycle":
                exit(PAGE::"Sales Cycles");
            DATABASE::"Close Opportunity Code":
                exit(PAGE::"Close Opportunity Codes");
            DATABASE::"Service Mgt. Setup":
                exit(PAGE::"Service Mgt. Setup");
            DATABASE::"Service Item":
                exit(PAGE::"Service Item List");
            DATABASE::"Service Hour":
                exit(PAGE::"Default Service Hours");
            DATABASE::"Work-Hour Template":
                exit(PAGE::"Work-Hour Templates");
            DATABASE::"Resource Service Zone":
                exit(PAGE::"Resource Service Zones");
            DATABASE::Loaner:
                exit(PAGE::"Loaner List");
            DATABASE::"Skill Code":
                exit(PAGE::"Skill Codes");
            DATABASE::"Fault Reason Code":
                exit(PAGE::"Fault Reason Codes");
            DATABASE::"Service Cost":
                exit(PAGE::"Service Costs");
            DATABASE::"Service Zone":
                exit(PAGE::"Service Zones");
            DATABASE::"Service Order Type":
                exit(PAGE::"Service Order Types");
            DATABASE::"Service Item Group":
                exit(PAGE::"Service Item Groups");
            DATABASE::"Service Shelf":
                exit(PAGE::"Service Shelves");
            DATABASE::"Service Status Priority Setup":
                exit(PAGE::"Service Order Status Setup");
            DATABASE::"Repair Status":
                exit(PAGE::"Repair Status Setup");
            DATABASE::"Service Price Group":
                exit(PAGE::"Service Price Groups");
            DATABASE::"Serv. Price Group Setup":
                exit(PAGE::"Serv. Price Group Setup");
            DATABASE::"Service Price Adjustment Group":
                exit(PAGE::"Serv. Price Adjmt. Group");
            DATABASE::"Serv. Price Adjustment Detail":
                exit(PAGE::"Serv. Price Adjmt. Detail");
            DATABASE::"Resolution Code":
                exit(PAGE::"Resolution Codes");
            DATABASE::"Fault Area":
                exit(PAGE::"Fault Areas");
            DATABASE::"Symptom Code":
                exit(PAGE::"Symptom Codes");
            DATABASE::"Fault Code":
                exit(PAGE::"Fault Codes");
            DATABASE::"Fault/Resol. Cod. Relationship":
                exit(PAGE::"Fault/Resol. Cod. Relationship");
            DATABASE::"Contract Group":
                exit(PAGE::"Service Contract Groups");
            DATABASE::"Service Contract Template":
                exit(PAGE::"Service Contract Template");
            DATABASE::"Service Contract Account Group":
                exit(PAGE::"Serv. Contract Account Groups");
            DATABASE::"Troubleshooting Header":
                exit(PAGE::Troubleshooting);
            DATABASE::"Purchases & Payables Setup":
                exit(PAGE::"Purchases & Payables Setup");
            DATABASE::Vendor:
                exit(PAGE::"Vendor List");
            DATABASE::"Vendor Posting Group":
                exit(PAGE::"Vendor Posting Groups");
            DATABASE::Purchasing:
                exit(PAGE::"Purchasing Codes");
            DATABASE::"Inventory Setup":
                exit(PAGE::"Inventory Setup");
            DATABASE::"Nonstock Item Setup":
                exit(PAGE::"Catalog Item Setup");
            DATABASE::"Item Tracking Code":
                exit(PAGE::"Item Tracking Codes");
            DATABASE::Item:
                exit(PAGE::"Item List");
            DATABASE::"Nonstock Item":
                exit(PAGE::"Catalog Item List");
            DATABASE::"Inventory Posting Group":
                exit(PAGE::"Inventory Posting Groups");
            DATABASE::"Inventory Posting Setup":
                exit(PAGE::"Inventory Posting Setup");
            DATABASE::"Unit of Measure":
                exit(PAGE::"Units of Measure");
            DATABASE::"Customer Price Group":
                exit(PAGE::"Customer Price Groups");
            DATABASE::"Item Discount Group":
                exit(PAGE::"Item Disc. Groups");
            DATABASE::Manufacturer:
                exit(PAGE::Manufacturers);
            DATABASE::"Item Category":
                exit(PAGE::"Item Categories");
            DATABASE::"Rounding Method":
                exit(PAGE::"Rounding Methods");
            DATABASE::Location:
                exit(PAGE::"Location List");
            DATABASE::"Transfer Route":
                exit(PAGE::"Transfer Routes");
            DATABASE::"Stockkeeping Unit":
                exit(PAGE::"Stockkeeping Unit List");
            DATABASE::"Warehouse Setup":
                exit(PAGE::"Warehouse Setup");
            DATABASE::"Resources Setup":
                exit(PAGE::"Resources Setup");
            DATABASE::Resource:
                exit(PAGE::"Resource List");
            DATABASE::"Resource Group":
                exit(PAGE::"Resource Groups");
            DATABASE::"Work Type":
                exit(PAGE::"Work Types");
            DATABASE::"Jobs Setup":
                exit(PAGE::"Jobs Setup");
            DATABASE::"Job Posting Group":
                exit(PAGE::"Job Posting Groups");
            DATABASE::"FA Setup":
                exit(PAGE::"Fixed Asset Setup");
            DATABASE::"Fixed Asset":
                exit(PAGE::"Fixed Asset List");
            DATABASE::Insurance:
                exit(PAGE::"Insurance List");
            DATABASE::"FA Posting Group":
                exit(PAGE::"FA Posting Groups");
            DATABASE::"FA Journal Template":
                exit(PAGE::"FA Journal Templates");
            DATABASE::"FA Reclass. Journal Template":
                exit(PAGE::"FA Reclass. Journal Templates");
            DATABASE::"Insurance Journal Template":
                exit(PAGE::"Insurance Journal Templates");
            DATABASE::"Depreciation Book":
                exit(PAGE::"Depreciation Book List");
            DATABASE::"FA Class":
                exit(PAGE::"FA Classes");
            DATABASE::"FA Subclass":
                exit(PAGE::"FA Subclasses");
            DATABASE::"FA Location":
                exit(PAGE::"FA Locations");
            DATABASE::"Insurance Type":
                exit(PAGE::"Insurance Types");
            DATABASE::Maintenance:
                exit(PAGE::Maintenance);
            DATABASE::"Human Resources Setup":
                exit(PAGE::"Human Resources Setup");
            DATABASE::Employee:
                exit(PAGE::"Employee List");
            DATABASE::"Cause of Absence":
                exit(PAGE::"Causes of Absence");
            DATABASE::"Cause of Inactivity":
                exit(PAGE::"Causes of Inactivity");
            DATABASE::"Grounds for Termination":
                exit(PAGE::"Grounds for Termination");
            DATABASE::"Employment Contract":
                exit(PAGE::"Employment Contracts");
            DATABASE::Qualification:
                exit(PAGE::Qualifications);
            DATABASE::Relative:
                exit(PAGE::Relatives);
            DATABASE::"Misc. Article":
                exit(PAGE::"Misc. Article Information");
            DATABASE::Confidential:
                exit(PAGE::Confidential);
            DATABASE::"Employee Statistics Group":
                exit(PAGE::"Employee Statistics Groups");
            DATABASE::Union:
                exit(PAGE::Unions);
            DATABASE::"Manufacturing Setup":
                exit(PAGE::"Manufacturing Setup");
            DATABASE::Family:
                exit(PAGE::Family);
            DATABASE::"Production BOM Header":
                exit(PAGE::"Production BOM");
            DATABASE::"Capacity Unit of Measure":
                exit(PAGE::"Capacity Units of Measure");
            DATABASE::"Work Shift":
                exit(PAGE::"Work Shifts");
            DATABASE::"Shop Calendar":
                exit(PAGE::"Shop Calendars");
            DATABASE::"Work Center Group":
                exit(PAGE::"Work Center Groups");
            DATABASE::"Standard Task":
                exit(PAGE::"Standard Tasks");
            DATABASE::"Routing Link":
                exit(PAGE::"Routing Links");
            DATABASE::Stop:
                exit(PAGE::"Stop Codes");
            DATABASE::Scrap:
                exit(PAGE::"Scrap Codes");
            DATABASE::"Machine Center":
                exit(PAGE::"Machine Center List");
            DATABASE::"Work Center":
                exit(PAGE::"Work Center List");
            DATABASE::"Routing Header":
                exit(PAGE::Routing);
            DATABASE::"Cost Type":
                exit(PAGE::"Cost Type List");
            DATABASE::"Cost Journal Template":
                exit(PAGE::"Cost Journal Templates");
            DATABASE::"Cost Allocation Source":
                exit(PAGE::"Cost Allocation");
            DATABASE::"Cost Allocation Target":
                exit(PAGE::"Cost Allocation Target List");
            DATABASE::"Cost Accounting Setup":
                exit(PAGE::"Cost Accounting Setup");
            DATABASE::"Cost Budget Name":
                exit(PAGE::"Cost Budget Names");
            DATABASE::"Cost Center":
                exit(PAGE::"Chart of Cost Centers");
            DATABASE::"Cost Object":
                exit(PAGE::"Chart of Cost Objects");
            DATABASE::"Cash Flow Setup":
                exit(PAGE::"Cash Flow Setup");
            DATABASE::"Cash Flow Forecast":
                exit(PAGE::"Cash Flow Forecast List");
            DATABASE::"Cash Flow Account":
                exit(PAGE::"Chart of Cash Flow Accounts");
            DATABASE::"Cash Flow Manual Expense":
                exit(PAGE::"Cash Flow Manual Expenses");
            DATABASE::"Cash Flow Manual Revenue":
                exit(PAGE::"Cash Flow Manual Revenues");
            DATABASE::"IC Partner":
                exit(PAGE::"IC Partner List");
            DATABASE::"Base Calendar":
                exit(PAGE::"Base Calendar List");
            DATABASE::"Finance Charge Text":
                exit(PAGE::"Reminder Text");
            DATABASE::"Currency for Fin. Charge Terms":
                exit(PAGE::"Currencies for Fin. Chrg Terms");
            DATABASE::"Currency for Reminder Level":
                exit(PAGE::"Currencies for Reminder Level");
            DATABASE::"Currency Exchange Rate":
                exit(PAGE::"Currency Exchange Rates");
            DATABASE::"VAT Statement Name":
                exit(PAGE::"VAT Statement Names");
            DATABASE::"VAT Statement Line":
                exit(PAGE::"VAT Statement");
            DATABASE::"No. Series Relationship":
                exit(PAGE::"No. Series Relationships");
            DATABASE::"User Setup":
                exit(PAGE::"User Setup");
            DATABASE::"Gen. Journal Template":
                exit(PAGE::"General Journal Template List");
            DATABASE::"Gen. Journal Batch":
                exit(PAGE::"General Journal Batches");
            DATABASE::"Gen. Journal Line":
                exit(PAGE::"General Journal");
            DATABASE::"Item Journal Template":
                exit(PAGE::"Item Journal Template List");
            DATABASE::"Item Journal Batch":
                exit(PAGE::"Item Journal Batches");
            DATABASE::"Customer Bank Account":
                exit(PAGE::"Customer Bank Account List");
            DATABASE::"Vendor Bank Account":
                exit(PAGE::"Vendor Bank Account List");
            DATABASE::"Cust. Invoice Disc.":
                exit(PAGE::"Cust. Invoice Discounts");
            DATABASE::"Vendor Invoice Disc.":
                exit(PAGE::"Vend. Invoice Discounts");
            DATABASE::"Dimension Value":
                exit(PAGE::"Dimension Value List");
            DATABASE::"Dimension Value Combination":
                exit(PAGE::"Dimension Combinations");
            DATABASE::"Default Dimension":
                exit(PAGE::"Default Dimensions");
            DATABASE::"Dimension Translation":
                exit(PAGE::"Dimension Translations");
            DATABASE::"Dimension Set Entry":
                exit(PAGE::"Dimension Set Entries");
            DATABASE::"VAT Report Setup":
                exit(PAGE::"VAT Report Setup");
            DATABASE::"VAT Registration No. Format":
                exit(PAGE::"VAT Registration No. Formats");
            DATABASE::"G/L Entry":
                exit(PAGE::"General Ledger Entries");
            DATABASE::"Cust. Ledger Entry":
                exit(PAGE::"Customer Ledger Entries");
            DATABASE::"Vendor Ledger Entry":
                exit(PAGE::"Vendor Ledger Entries");
            DATABASE::"Item Ledger Entry":
                exit(PAGE::"Item Ledger Entries");
            DATABASE::"Sales Header":
                exit(PAGE::"Sales List");
            DATABASE::"Purchase Header":
                exit(PAGE::"Purchase List");
            DATABASE::"G/L Register":
                exit(PAGE::"G/L Registers");
            DATABASE::"Item Register":
                exit(PAGE::"Item Registers");
            DATABASE::"Item Journal Line":
                exit(PAGE::"Item Journal Lines");
            DATABASE::"Sales Shipment Header":
                exit(PAGE::"Posted Sales Shipments");
            DATABASE::"Sales Invoice Header":
                exit(PAGE::"Posted Sales Invoices");
            DATABASE::"Sales Cr.Memo Header":
                exit(PAGE::"Posted Sales Credit Memos");
            DATABASE::"Purch. Rcpt. Header":
                exit(PAGE::"Posted Purchase Receipts");
            DATABASE::"Purch. Inv. Header":
                exit(PAGE::"Posted Purchase Invoices");
            DATABASE::"Purch. Cr. Memo Hdr.":
                exit(PAGE::"Posted Purchase Credit Memos");
#if not CLEAN21
            DATABASE::"Sales Price":
                exit(PAGE::"Sales Prices");
            DATABASE::"Purchase Price":
                exit(PAGE::"Purchase Prices");
#endif
            DATABASE::"Price List Line":
                exit(Page::"Price List Line Review");
            DATABASE::"VAT Entry":
                exit(PAGE::"VAT Entries");
            DATABASE::"FA Ledger Entry":
                exit(PAGE::"FA Ledger Entries");
            DATABASE::"Value Entry":
                exit(PAGE::"Value Entries");
            DATABASE::"Source Code Setup":
                exit(PAGE::"Source Code Setup");
            else begin
                OnFindPage(TableID, PageID);
                exit(PageID);
            end;
        end;
    end;

    procedure GetConfigTables(var AllObj: Record AllObj; IncludeWithDataOnly: Boolean; IncludeRelatedTables: Boolean; IncludeDimensionTables: Boolean; IncludeLicensedTablesOnly: Boolean; IncludeReferringTable: Boolean)
    var
        TempInt: Record "Integer" temporary;
        TableInfo: Record "Table Information";
        ConfigLine: Record "Config. Line";
        "Field": Record "Field";
        NextLineNo: Integer;
        NextVertNo: Integer;
        Include: Boolean;
    begin
        if not HideDialog then
            ConfigProgressBar.Init(AllObj.Count, 1, Text023);

        TempInt.DeleteAll();

        NextLineNo := 10000;
        ConfigLine.Reset();
        if ConfigLine.FindLast() then
            NextLineNo := ConfigLine."Line No." + 10000;

        NextVertNo := 0;
        ConfigLine.SetCurrentKey("Vertical Sorting");
        if ConfigLine.FindLast() then
            NextVertNo := ConfigLine."Vertical Sorting" + 1;

        if AllObj.FindSet() then
            repeat
                if not HideDialog then
                    ConfigProgressBar.Update(AllObj."Object Name");
                Include := true;
                if IncludeWithDataOnly then begin
                    Include := false;
                    TableInfo.SetRange("Company Name", CompanyName);
                    TableInfo.SetRange("Table No.", AllObj."Object ID");
                    if TableInfo.FindFirst() then
                        if TableInfo."No. of Records" > 0 then
                            Include := true;
                end;
                if Include then begin
                    if IncludeReferringTable then
                        InsertTempInt(TempInt, AllObj."Object ID", IncludeLicensedTablesOnly);
                    if IncludeRelatedTables then begin
                        ConfigPackageMgt.SetFieldFilter(Field, AllObj."Object ID", 0);
                        Field.SetFilter(RelationTableNo, '<>%1&<>%2&..%3', 0, AllObj."Object ID", 99000999);
                        if Field.FindSet() then
                            repeat
                                InsertTempInt(TempInt, Field.RelationTableNo, IncludeLicensedTablesOnly);
                            until Field.Next() = 0;
                    end;
                    if IncludeDimensionTables then
                        if CheckDimTables(AllObj."Object ID") then begin
                            InsertDimTables(TempInt, IncludeLicensedTablesOnly);
                            IncludeDimensionTables := false;
                        end;
                end;
            until AllObj.Next() = 0;

        if TempInt.FindSet() then
            repeat
                InsertConfigLine(TempInt.Number, NextLineNo, NextVertNo);
            until TempInt.Next() = 0;

        if not HideDialog then
            ConfigProgressBar.Close();
    end;

    local procedure InsertConfigLine(TableID: Integer; var NextLineNo: Integer; var NextVertNo: Integer)
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.Init();
        ConfigLine.Validate("Line Type", ConfigLine."Line Type"::Table);
        ConfigLine.Validate("Table ID", TableID);
        ConfigLine."Line No." := NextLineNo;
        NextLineNo := NextLineNo + 10000;
        ConfigLine."Vertical Sorting" := NextVertNo;
        NextVertNo := NextVertNo + 1;
        ConfigLine.Insert(true);
    end;

    local procedure CheckDimTables(TableID: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        ConfigPackageMgt.SetFieldFilter(Field, TableID, 0);
        if Field.FindSet() then
            repeat
                if IsDimSetIDField(Field.TableNo, Field."No.") then
                    exit(true);
            until Field.Next() = 0;
    end;

    local procedure CheckTable(TableID: Integer): Boolean
    begin
        exit(IsNormalTable(TableID) and TableIsInAllowedRange(TableID));
    end;

    local procedure InsertDimTables(var TempInt: Record "Integer"; IncludeLicensedTablesOnly: Boolean)
    begin
        InsertTempInt(TempInt, DATABASE::Dimension, IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, DATABASE::"Dimension Value", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, DATABASE::"Dimension Combination", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, DATABASE::"Dimension Value Combination", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, DATABASE::"Dimension Set Entry", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, DATABASE::"Dimension Set Tree Node", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, DATABASE::"Default Dimension", IncludeLicensedTablesOnly);
        InsertTempInt(TempInt, DATABASE::"Default Dimension Priority", IncludeLicensedTablesOnly);
    end;

    procedure IsDefaultDimTable(TableID: Integer) Result: Boolean
    begin
        case TableID of
            DATABASE::"G/L Account",
          DATABASE::Customer,
          DATABASE::Vendor,
          DATABASE::Item,
          DATABASE::"Resource Group",
          DATABASE::Resource,
          DATABASE::Job,
          DATABASE::"Bank Account",
          DATABASE::Employee,
          DATABASE::"Fixed Asset",
          DATABASE::Insurance,
          DATABASE::"Responsibility Center",
          DATABASE::"Work Center",
          DATABASE::"Salesperson/Purchaser",
          DATABASE::Campaign,
          DATABASE::"Cash Flow Manual Expense",
          DATABASE::"Cash Flow Manual Revenue":
                exit(true);
        end;

        OnAfterIsDefaultDimTable(TableID, Result);
    end;

    procedure IsDimSetIDTable(TableID: Integer) Result: Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        Result := RecRef.FieldExist(DATABASE::"Dimension Set Entry");
        OnAfterIsDimSetIDTable(TableID, Result);
    end;

    local procedure IsDimSetIDField(TableID: Integer; FieldID: Integer): Boolean
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
    begin
        exit(
          (FieldID = DATABASE::"Dimension Set Entry") or
          (ConfigValidateMgt.GetRelationTableID(TableID, FieldID) = DATABASE::"Dimension Value"));
    end;

    local procedure TableIsInAllowedRange(TableID: Integer) Result: Boolean
    begin
        // This condition duplicates table relation of ConfigLine."Table ID" field to prevent runtime errors
        Result := TableID in [1 .. 99000999,
                              DATABASE::"Permission Set",
                              DATABASE::Permission,
                              DATABASE::"Tenant Permission Set Rel.",
                              DATABASE::"Tenant Permission Set",
                              DATABASE::"Tenant Permission"];
        OnAfterTableIsInAllowedRange(TableID, Result);
    end;

    local procedure IsNormalTable(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.TableType = TableMetadata.TableType::Normal);
    end;

    procedure IsSystemTable(TableID: Integer) Result: Boolean
    begin
        Result := (TableID > 2000000000) and not (TableID in [DATABASE::"Permission Set",
                                                              DATABASE::Permission,
                                                              DATABASE::"Tenant Permission Set Rel.",
                                                              DATABASE::"Tenant Permission Set",
                                                              DATABASE::"Tenant Permission"]);
        OnAfterIsSystemTable(TableID, Result);
    end;

    procedure AssignParentLineNos()
    var
        ConfigLine: Record "Config. Line";
        LastAreaLineNo: Integer;
        LastGroupLineNo: Integer;
    begin
        with ConfigLine do begin
            Reset();
            SetCurrentKey("Vertical Sorting");
            if FindSet() then
                repeat
                    case "Line Type" of
                        "Line Type"::Area:
                            begin
                                "Parent Line No." := 0;
                                LastAreaLineNo := "Line No.";
                                LastGroupLineNo := 0;
                            end;
                        "Line Type"::Group:
                            begin
                                "Parent Line No." := LastAreaLineNo;
                                LastGroupLineNo := "Line No.";
                            end;
                        "Line Type"::Table:
                            if LastGroupLineNo <> 0 then
                                "Parent Line No." := LastGroupLineNo
                            else
                                "Parent Line No." := LastAreaLineNo;
                    end;
                    Modify();
                until Next() = 0;
        end;
    end;

    procedure MakeTableFilter(var ConfigLine: Record "Config. Line"; Export: Boolean) "Filter": Text
    var
        AddDimTables: Boolean;
    begin
        Filter := '';
        if ConfigLine.FindSet() then
            repeat
                ConfigLine.CheckBlocked();
                if (ConfigLine."Table ID" > 0) and (ConfigLine.Status <= ConfigLine.Status::Completed) then
                    Filter += Format(ConfigLine."Table ID") + '|';
                AddDimTables := AddDimTables or ConfigLine."Dimensions as Columns";
            until ConfigLine.Next() = 0;
        if AddDimTables and not Export then
            Filter += StrSubstNo('%1|%2|', DATABASE::"Dimension Value", DATABASE::"Default Dimension");
        if Filter <> '' then
            Filter := CopyStr(Filter, 1, StrLen(Filter) - 1);

        exit(Filter);
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure InsertTempInt(var TempInt: Record "Integer"; TableId: Integer; IncludeLicensedTablesOnly: Boolean)
    var
        ConfigLine: Record "Config. Line";
        EnvironmentInformation: Codeunit "Environment Information";
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
    begin
        if CheckTable(TableId) then begin
            TempInt.Number := TableId;

            ConfigLine.Init();
            ConfigLine."Line Type" := ConfigLine."Line Type"::Table;
            ConfigLine."Table ID" := TableId;
            if IncludeLicensedTablesOnly then begin
                if EnvironmentInformation.IsSaaS() then begin
                    if EffectivePermissionsMgt.HasDirectRIMPermissionsOnTableData(TableId) then
                        if TempInt.Insert() then;
                end
                else begin
                    ConfigLine.CalcFields("Licensed Table");
                    if ConfigLine."Licensed Table" then
                        if TempInt.Insert() then;
                end;
            end else
                if TempInt.Insert() then;
        end;
    end;

    procedure DimensionFieldID(): Integer
    begin
        exit(999999900);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPage(TableID: Integer; var PageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDimSetIDTable(TableID: Integer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDefaultDimTable(TableID: Integer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTableIsInAllowedRange(TableID: Integer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsSystemTable(TableID: Integer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDataDialog(var ConfigLine: Record "Config. Line"; NewCompanyName: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferContentOnBeforeToCompanyFieldRefValue(FieldRec: Record "Field"; FromCompanyFieldRef: FieldRef)
    begin
    end;
}

