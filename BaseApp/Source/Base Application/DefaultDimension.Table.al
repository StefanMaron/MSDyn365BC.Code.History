﻿table 352 "Default Dimension"
{
    Caption = 'Default Dimension';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));

            trigger OnLookup()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                Clear(TempAllObjWithCaption);
                DimMgt.DefaultDimObjectNoList(TempAllObjWithCaption);
                if PAGE.RunModal(PAGE::Objects, TempAllObjWithCaption) = ACTION::LookupOK then begin
                    "Table ID" := TempAllObjWithCaption."Object ID";
                    Validate("Table ID");
                end;
            end;

            trigger OnValidate()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                CalcFields("Table Caption");
                DimMgt.DefaultDimObjectNoList(TempAllObjWithCaption);
                TempAllObjWithCaption."Object Type" := TempAllObjWithCaption."Object Type"::Table;
                TempAllObjWithCaption."Object ID" := "Table ID";
                if not TempAllObjWithCaption.Find then
                    FieldError("Table ID");
            end;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                RecRef: RecordRef;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "No." = '' then
                    exit;
                RecRef.Open("Table ID");
                SetRangeToLastFieldInPrimaryKey(RecRef, "No.");
                if RecRef.IsEmpty then
                    Error(NoValidateErr, "No.", RecRef.Caption);
                RecRef.Close;
            end;
        }
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                CheckDimension("Dimension Code");
                UpdateDimensionId;
                if "Dimension Code" <> xRec."Dimension Code" then
                    Validate("Dimension Value Code", '');
            end;
        }
        field(4; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Dimension Code"));

            trigger OnValidate()
            begin
                CheckDimensionValue("Dimension Code", "Dimension Value Code");
                UpdateDimensionValueId;
            end;
        }
        field(5; "Value Posting"; Option)
        {
            Caption = 'Value Posting';
            OptionCaption = ' ,Code Mandatory,Same Code,No Code';
            OptionMembers = " ","Code Mandatory","Same Code","No Code";

            trigger OnValidate()
            begin
                if "Value Posting" = "Value Posting"::"No Code" then
                    TestField("Dimension Value Code", '');
            end;
        }
        field(6; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Multi Selection Action"; Option)
        {
            Caption = 'Multi Selection Action';
            OptionCaption = ' ,Change,Delete';
            OptionMembers = " ",Change,Delete;
        }
        field(8; "Parent Type"; Enum "Default Dimension Parent Type")
        {
            Caption = 'Parent Type';

            trigger OnValidate()
            begin
                case "Parent Type" of
                    "Parent Type"::Customer:
                        "Table ID" := Database::Customer;
                    "Parent Type"::Employee:
                        "Table ID" := Database::Employee;
                    "Parent Type"::Item:
                        "Table ID" := Database::Item;
                    "Parent Type"::Vendor:
                        "Table ID" := Database::Vendor;
                end;
            end;
        }
        field(8000; ParentId; Guid)
        {
            Caption = 'ParentId';
            DataClassification = SystemMetadata;
            TableRelation = IF ("Table ID" = CONST(15)) "G/L Account".SystemId
            ELSE
            IF ("Table ID" = CONST(18)) Customer.SystemId
            ELSE
            IF ("Table ID" = CONST(23)) Vendor.SystemId
            ELSE
            IF ("Table ID" = CONST(5200)) Employee.SystemId;

            trigger OnValidate()
            begin
                if "Parent Type" <> "Parent Type"::" " then
                    UpdateNo(ParentId, "Parent Type")
                else
                    UpdateTableIdAndNo(ParentId);
            end;
        }
        field(8001; DimensionId; Guid)
        {
            Caption = 'DimensionId';
            DataClassification = SystemMetadata;
            TableRelation = Dimension.SystemId;

            trigger OnValidate()
            var
                Dimension: Record Dimension;
            begin
                if not Dimension.GetBySystemId(DimensionId) then
                    Error(DimensionIdDoesNotMatchADimensionErr);

                CheckDimension(Dimension.Code);
                "Dimension Code" := Dimension.Code;
            end;
        }
        field(8002; DimensionValueId; Guid)
        {
            Caption = 'DimensionValueId';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".SystemId;

            trigger OnValidate()
            var
                DimensionValue: Record "Dimension Value";
            begin
                if IsNullGuid(DimensionValueId) then begin
                    "Dimension Value Code" := '';
                    exit;
                end;

                if not DimensionValue.GetBySystemId(DimensionValueId) then
                    Error(DimensionValueIdDoesNotMatchADimensionValueErr);

                if "Dimension Code" = '' then
                    "Dimension Code" := DimensionValue."Dimension Code"
                else
                    if "Dimension Code" <> DimensionValue."Dimension Code" then
                        Error(DimensionIdMismatchErr);
                CheckDimensionValue("Dimension Code", DimensionValue.Code);
                "Dimension Value Code" := DimensionValue.Code;
            end;
        }
    }

    keys
    {
        key(Key1; "Table ID", "No.", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        GLSetup.Get();
        if "Dimension Code" = GLSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", '');
        if "Dimension Code" = GLSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", '');
        DimMgt.DefaultDimOnDelete(Rec);
    end;

    trigger OnInsert()
    begin
        GLSetup.Get();
        if "Dimension Code" = GLSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", "Dimension Value Code");
        if "Dimension Code" = GLSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", "Dimension Value Code");
        DimMgt.DefaultDimOnInsert(Rec);
        UpdateParentId;
    end;

    trigger OnModify()
    begin
        GLSetup.Get();
        if "Dimension Code" = GLSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", "Dimension Value Code");
        if "Dimension Code" = GLSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", "Dimension Value Code");
        DimMgt.DefaultDimOnModify(Rec);
    end;

    trigger OnRename()
    begin
        if ("Table ID" <> xRec."Table ID") or ("Dimension Code" <> xRec."Dimension Code") then
            Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You can''t rename a %1.';
        GLSetup: Record "General Ledger Setup";
        DimMgt: Codeunit DimensionManagement;
        DimensionIdDoesNotMatchADimensionErr: Label 'The "dimensionId" does not match to a Dimension.', Locked = true;
        DimensionValueIdDoesNotMatchADimensionValueErr: Label 'The "dimensionValueId" does not match to a Dimension Value.', Locked = true;
        DimensionIdMismatchErr: Label 'The "dimensionId" and "dimensionValueId" match to different Dimension records.', Locked = true;
        ParentIdDoesNotMatchAnIntegrationRecordErr: Label 'The "parenteId" does not match to any entity.', Locked = true;
        RequestedRecordIsNotSupportedErr: Label 'Images are not supported for requested entity - %1.', Locked = true;
        NoValidateErr: Label 'The field No. of table Default Dimension contains a value (%1) that cannot be found in the related table (%2).', Comment = '%1 - a master table record key value; %2 - table caption. ';
        MultipleParentsFoundErr: Label 'Multiple parents have been found for the specified criteria.';
        ParentNotFoundErr: Label 'Parent is not found.';

    procedure GetCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
        CurrTableID: Integer;
        NewTableID: Integer;
        NewNo: Code[20];
        SourceTableName: Text[100];
    begin
        if not Evaluate(NewTableID, GetFilter("Table ID")) then
            exit('');

        if NewTableID = 0 then
            if GetRangeMin("Table ID") = GetRangeMax("Table ID") then
                NewTableID := GetRangeMin("Table ID")
            else
                NewTableID := 0;

        if NewTableID <> CurrTableID then
            SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, NewTableID);
        CurrTableID := NewTableID;

        if GetFilter("No.") <> '' then
            if GetRangeMin("No.") = GetRangeMax("No.") then
                NewNo := GetRangeMin("No.")
            else
                NewNo := '';

        if NewTableID <> 0 then
            exit(StrSubstNo('%1 %2', SourceTableName, NewNo));

        exit('');
    end;

    local procedure UpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateGlobalDimCode(GlobalDimCodeNo, TableID, AccNo, NewDimValue, IsHandled);
        if IsHandled then
            exit;

        case TableID of
            DATABASE::"G/L Account":
                UpdateGLAccGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::Customer:
                UpdateCustGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::Vendor:
                UpdateVendGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::Item:
                UpdateItemGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Resource Group":
                UpdateResGrGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::Resource:
                UpdateResGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::Job:
                UpdateJobGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Bank Account":
                UpdateBankGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::Employee:
                UpdateEmpoyeeGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Fixed Asset":
                UpdateFAGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::Insurance:
                UpdateInsuranceGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Responsibility Center":
                UpdateRespCenterGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Work Center":
                UpdateWorkCenterGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Salesperson/Purchaser":
                UpdateSalesPurchGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::Campaign:
                UpdateCampaignGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Customer Template":
                UpdateCustTempGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Cash Flow Manual Expense":
                UpdateNeutrPayGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            DATABASE::"Cash Flow Manual Revenue":
                UpdateNeutrRevGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Vendor Templ.":
                UpdateVendorTemplGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Customer Templ.":
                UpdateCustomerTemplGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Item Templ.":
                UpdateItemTemplGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Employee Templ.":
                UpdateEmployeeTemplGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            else
                OnAfterUpdateGlobalDimCode(GlobalDimCodeNo, TableID, AccNo, NewDimValue);
        end;
    end;

    local procedure UpdateGLAccGlobalDimCode(GlobalDimCodeNo: Integer; GLAccNo: Code[20]; NewDimValue: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if GLAcc.Get(GLAccNo) then begin
            case GlobalDimCodeNo of
                1:
                    GLAcc."Global Dimension 1 Code" := NewDimValue;
                2:
                    GLAcc."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateGLAccGlobalDimCodeOnCaseElse(GlobalDimCodeNo, GLAccNo, NewDimValue);
            end;
            GLAcc.Modify(true);
        end;
    end;

    local procedure UpdateCustGlobalDimCode(GlobalDimCodeNo: Integer; CustNo: Code[20]; NewDimValue: Code[20])
    var
        Cust: Record Customer;
    begin
        if Cust.Get(CustNo) then begin
            case GlobalDimCodeNo of
                1:
                    Cust."Global Dimension 1 Code" := NewDimValue;
                2:
                    Cust."Global Dimension 2 Code" := NewDimValue;
            end;
            Cust.Modify(true);
        end;
    end;

    local procedure UpdateVendGlobalDimCode(GlobalDimCodeNo: Integer; VendNo: Code[20]; NewDimValue: Code[20])
    var
        Vend: Record Vendor;
    begin
        if Vend.Get(VendNo) then begin
            case GlobalDimCodeNo of
                1:
                    Vend."Global Dimension 1 Code" := NewDimValue;
                2:
                    Vend."Global Dimension 2 Code" := NewDimValue;
            end;
            Vend.Modify(true);
        end;
    end;

    local procedure UpdateItemGlobalDimCode(GlobalDimCodeNo: Integer; ItemNo: Code[20]; NewDimValue: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then begin
            case GlobalDimCodeNo of
                1:
                    Item."Global Dimension 1 Code" := NewDimValue;
                2:
                    Item."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateItemGlobalDimCodeOnCaseElse(GlobalDimCodeNo, ItemNo, NewDimValue);
            end;
            Item.Modify(true);
        end;
    end;

    local procedure UpdateResGrGlobalDimCode(GlobalDimCodeNo: Integer; ResGrNo: Code[20]; NewDimValue: Code[20])
    var
        ResGr: Record "Resource Group";
    begin
        if ResGr.Get(ResGrNo) then begin
            case GlobalDimCodeNo of
                1:
                    ResGr."Global Dimension 1 Code" := NewDimValue;
                2:
                    ResGr."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateResGrGlobalDimCodeOnCaseElse(GlobalDimCodeNo, ResGrNo, NewDimValue);
            end;
            ResGr.Modify(true);
        end;
    end;

    local procedure UpdateResGlobalDimCode(GlobalDimCodeNo: Integer; ResNo: Code[20]; NewDimValue: Code[20])
    var
        Res: Record Resource;
    begin
        if Res.Get(ResNo) then begin
            case GlobalDimCodeNo of
                1:
                    Res."Global Dimension 1 Code" := NewDimValue;
                2:
                    Res."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateResGlobalDimCodeCaseElse(GlobalDimCodeNo, ResNo, NewDimValue);
            end;
            Res.Modify(true);
        end;
    end;

    local procedure UpdateJobGlobalDimCode(GlobalDimCodeNo: Integer; JobNo: Code[20]; NewDimValue: Code[20])
    var
        Job: Record Job;
    begin
        if Job.Get(JobNo) then begin
            case GlobalDimCodeNo of
                1:
                    Job."Global Dimension 1 Code" := NewDimValue;
                2:
                    Job."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateJobGlobalDimCodeCaseElse(GlobalDimCodeNo, JobNo, NewDimValue);
            end;
            Job.Modify(true);
        end;
    end;

    local procedure UpdateBankGlobalDimCode(GlobalDimCodeNo: Integer; BankAccNo: Code[20]; NewDimValue: Code[20])
    var
        BankAcc: Record "Bank Account";
    begin
        if BankAcc.Get(BankAccNo) then begin
            case GlobalDimCodeNo of
                1:
                    BankAcc."Global Dimension 1 Code" := NewDimValue;
                2:
                    BankAcc."Global Dimension 2 Code" := NewDimValue;
            end;
            BankAcc.Modify(true);
        end;
    end;

    local procedure UpdateEmpoyeeGlobalDimCode(GlobalDimCodeNo: Integer; EmployeeNo: Code[20]; NewDimValue: Code[20])
    var
        Employee: Record Employee;
    begin
        if Employee.Get(EmployeeNo) then begin
            case GlobalDimCodeNo of
                1:
                    Employee."Global Dimension 1 Code" := NewDimValue;
                2:
                    Employee."Global Dimension 2 Code" := NewDimValue;
            end;
            Employee.Modify(true);
        end;
    end;

    local procedure UpdateFAGlobalDimCode(GlobalDimCodeNo: Integer; FANo: Code[20]; NewDimValue: Code[20])
    var
        FA: Record "Fixed Asset";
    begin
        if FA.Get(FANo) then begin
            case GlobalDimCodeNo of
                1:
                    FA."Global Dimension 1 Code" := NewDimValue;
                2:
                    FA."Global Dimension 2 Code" := NewDimValue;
            end;
            FA.Modify(true);
        end;
    end;

    local procedure UpdateInsuranceGlobalDimCode(GlobalDimCodeNo: Integer; InsuranceNo: Code[20]; NewDimValue: Code[20])
    var
        Insurance: Record Insurance;
    begin
        if Insurance.Get(InsuranceNo) then begin
            case GlobalDimCodeNo of
                1:
                    Insurance."Global Dimension 1 Code" := NewDimValue;
                2:
                    Insurance."Global Dimension 2 Code" := NewDimValue;
            end;
            Insurance.Modify(true);
        end;
    end;

    local procedure UpdateRespCenterGlobalDimCode(GlobalDimCodeNo: Integer; RespCenterNo: Code[20]; NewDimValue: Code[20])
    var
        RespCenter: Record "Responsibility Center";
    begin
        if RespCenter.Get(RespCenterNo) then begin
            case GlobalDimCodeNo of
                1:
                    RespCenter."Global Dimension 1 Code" := NewDimValue;
                2:
                    RespCenter."Global Dimension 2 Code" := NewDimValue;
            end;
            RespCenter.Modify(true);
        end;
    end;

    local procedure UpdateWorkCenterGlobalDimCode(GlobalDimCodeNo: Integer; WorkCenterNo: Code[20]; NewDimValue: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        if WorkCenter.Get(WorkCenterNo) then begin
            case GlobalDimCodeNo of
                1:
                    WorkCenter."Global Dimension 1 Code" := NewDimValue;
                2:
                    WorkCenter."Global Dimension 2 Code" := NewDimValue;
            end;
            WorkCenter.Modify(true);
        end;
    end;

    local procedure UpdateSalesPurchGlobalDimCode(GlobalDimCodeNo: Integer; SalespersonPurchaserNo: Code[20]; NewDimValue: Code[20])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if SalespersonPurchaser.Get(SalespersonPurchaserNo) then begin
            case GlobalDimCodeNo of
                1:
                    SalespersonPurchaser."Global Dimension 1 Code" := NewDimValue;
                2:
                    SalespersonPurchaser."Global Dimension 2 Code" := NewDimValue;
            end;
            SalespersonPurchaser.Modify(true);
        end;
    end;

    local procedure UpdateCampaignGlobalDimCode(GlobalDimCodeNo: Integer; CampaignNo: Code[20]; NewDimValue: Code[20])
    var
        Campaign: Record Campaign;
    begin
        if Campaign.Get(CampaignNo) then begin
            case GlobalDimCodeNo of
                1:
                    Campaign."Global Dimension 1 Code" := NewDimValue;
                2:
                    Campaign."Global Dimension 2 Code" := NewDimValue;
            end;
            Campaign.Modify(true);
        end;
    end;

    local procedure UpdateCustTempGlobalDimCode(GlobalDimCodeNo: Integer; CustTemplateNo: Code[20]; NewDimValue: Code[20])
    var
        CustTemplate: Record "Customer Template";
    begin
        if CustTemplate.Get(CustTemplateNo) then begin
            case GlobalDimCodeNo of
                1:
                    CustTemplate."Global Dimension 1 Code" := NewDimValue;
                2:
                    CustTemplate."Global Dimension 2 Code" := NewDimValue;
            end;
            CustTemplate.Modify(true);
        end;
    end;

    local procedure UpdateNeutrPayGlobalDimCode(GlobalDimCodeNo: Integer; CFManualExpenseNo: Code[20]; NewDimValue: Code[20])
    var
        CFManualExpense: Record "Cash Flow Manual Expense";
    begin
        if CFManualExpense.Get(CFManualExpenseNo) then begin
            case GlobalDimCodeNo of
                1:
                    CFManualExpense."Global Dimension 1 Code" := NewDimValue;
                2:
                    CFManualExpense."Global Dimension 2 Code" := NewDimValue;
            end;
            CFManualExpense.Modify(true);
        end;
    end;

    local procedure UpdateNeutrRevGlobalDimCode(GlobalDimCodeNo: Integer; CFManualRevenueNo: Code[20]; NewDimValue: Code[20])
    var
        CFManualRevenue: Record "Cash Flow Manual Revenue";
    begin
        if CFManualRevenue.Get(CFManualRevenueNo) then begin
            case GlobalDimCodeNo of
                1:
                    CFManualRevenue."Global Dimension 1 Code" := NewDimValue;
                2:
                    CFManualRevenue."Global Dimension 2 Code" := NewDimValue;
            end;
            CFManualRevenue.Modify(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    local procedure CheckDimension(DimensionCode: Code[20])
    begin
        if not DimMgt.CheckDim(DimensionCode) then
            Error(DimMgt.GetDimErr);
    end;

    local procedure CheckDimensionValue(DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        if not DimMgt.CheckDimValue(DimensionCode, DimensionValueCode) then
            Error(DimMgt.GetDimErr);
        if "Value Posting" = "Value Posting"::"No Code" then
            TestField("Dimension Value Code", '');
    end;

    local procedure SetRangeToLastFieldInPrimaryKey(RecRef: RecordRef; Value: Code[20])
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
        FieldRef.SetRange(Value);
    end;

    local procedure UpdateNo(ParentId: Guid; ParentType: Enum "Default Dimension Parent Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
    begin
        case ParentType of
            "Parent Type"::Customer:
                if Customer.GetBySystemId(ParentId) then begin
                    "No." := Customer."No.";
                    exit;
                end;
            "Parent Type"::Employee:
                if Employee.GetBySystemId(ParentId) then begin
                    "No." := Employee."No.";
                    exit;
                end;
            "Parent Type"::Item:
                if Item.GetBySystemId(ParentId) then begin
                    "No." := Item."No.";
                    exit;
                end;
            "Parent Type"::Vendor:
                if Vendor.GetBySystemId(ParentId) then begin
                    "No." := Vendor."No.";
                    exit;
                end;
        end;
        Error(ParentNotFoundErr);
    end;

    local procedure UpdateTableIdAndNo(Id: Guid)
    var
        IntegrationRecord: Record "Integration Record";
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        IntegrationManagement: Codeunit "Integration Management";
        ParentRecordRef: RecordRef;
        ParentRecordRefId: RecordId;
    begin
        if IntegrationManagement.GetIntegrationIsEnabledOnTheSystem() then begin
            if not IntegrationRecord.Get(Id) then
                Error(ParentIdDoesNotMatchAnIntegrationRecordErr);
            ParentRecordRefId := IntegrationRecord."Record ID";
        end else begin
            if not GetRecordRefFromFilter(Id, ParentRecordRef) then
                Error(ParentIdDoesNotMatchAnIntegrationRecordErr);

            ParentRecordRefId := ParentRecordRef.RecordId;
        end;

        case ParentRecordRefId.TableNo of
            DATABASE::Item:
                begin
                    Item.Get(ParentRecordRefId);
                    "No." := Item."No.";
                    "Parent Type" := "Parent Type"::Item;
                end;
            DATABASE::Customer:
                begin
                    Customer.Get(ParentRecordRefId);
                    "No." := Customer."No.";
                    "Parent Type" := "Parent Type"::Customer;
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(ParentRecordRefId);
                    "No." := Vendor."No.";
                    "Parent Type" := "Parent Type"::Vendor;
                end;
            DATABASE::Employee:
                begin
                    Employee.Get(ParentRecordRefId);
                    "No." := Employee."No.";
                    "Parent Type" := "Parent Type"::Employee;
                end;
            else
                ThrowEntityNotSupportedError(ParentRecordRefId.TableNo);
        end;

        "Table ID" := ParentRecordRefId.TableNo;
    end;

    local procedure GetRecordRefFromFilter(IDFilter: Text; var ParentRecordRef: RecordRef): Boolean
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        RecordFound: Boolean;
    begin
        Item.SetFilter(SystemId, IDFilter);
        if Item.FindFirst() then begin
            ParentRecordRef.GetTable(Item);
            RecordFound := true;
        end;

        Customer.SetFilter(SystemId, IDFilter);
        if Customer.FindFirst() then begin
            if not RecordFound then begin
                ParentRecordRef.GetTable(Customer);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);
        end;

        Vendor.SetFilter(SystemId, IDFilter);
        if Vendor.FindFirst() then begin
            if not RecordFound then begin
                ParentRecordRef.GetTable(Vendor);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);
        end;

        Employee.SetFilter(SystemId, IDFilter);
        if Employee.FindFirst() then begin
            if not RecordFound then begin
                ParentRecordRef.GetTable(Employee);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);
        end;

        exit(RecordFound);
    end;

    local procedure UpdateParentType(): Boolean
    var
        NewParentType: Enum "Default Dimension Parent Type";
    begin
        case "Table ID" of
            DATABASE::Item:
                NewParentType := "Parent Type"::Item;
            DATABASE::Customer:
                NewParentType := "Parent Type"::Customer;
            DATABASE::Vendor:
                NewParentType := "Parent Type"::Vendor;
            DATABASE::Employee:
                NewParentType := "Parent Type"::Employee;
            else
                NewParentType := "Parent Type"::" ";
        end;

        if NewParentType = "Parent Type" then
            exit(false);

        "Parent Type" := NewParentType;
        exit(true);
    end;

    local procedure UpdateParentId(): Boolean
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        NewParentId: Guid;
    begin
        case "Table ID" of
            DATABASE::Item:
                if Item.Get("No.") then
                    NewParentId := Item.SystemId;
            DATABASE::Customer:
                if Customer.Get("No.") then
                    NewParentId := Customer.SystemId;
            DATABASE::Vendor:
                if Vendor.Get("No.") then
                    NewParentId := Vendor.SystemId;
            DATABASE::Employee:
                if Employee.Get("No.") then
                    NewParentId := Employee.SystemId;
        end;

        if NewParentId = ParentId then
            exit(false);

        ParentId := NewParentId;
        exit(true);
    end;

    local procedure UpdateDimensionId(): Boolean
    var
        Dimension: Record Dimension;
    begin
        if not Dimension.Get("Dimension Code") then
            exit(false);

        if DimensionId = Dimension.SystemId then
            exit(false);

        DimensionId := Dimension.SystemId;
        exit(true);
    end;

    local procedure UpdateDimensionValueId(): Boolean
    var
        DimensionValue: Record "Dimension Value";
    begin
        if DimensionValue.Get("Dimension Code", "Dimension Value Code") then begin
            if DimensionValueId = DimensionValue.SystemId then
                exit(false);

            DimensionValueId := DimensionValue.SystemId;
            exit(true);
        end;

        if "Dimension Value Code" = '' then begin
            if IsNullGuid(DimensionValueId) then
                exit(false);

            Clear(DimensionValueId);
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateReferencedIds()
    begin
        if UpdateReferencedIdFields() then
            Modify(false);
    end;

    procedure UpdateReferencedIdFields(): Boolean
    var
        Modified: Boolean;
    begin
        Modified := UpdateParentId();
        Modified := UpdateParentType();
        Modified := Modified or UpdateDimensionId();
        Modified := Modified or UpdateDimensionValueId();
        exit(Modified);
    end;

    local procedure ThrowEntityNotSupportedError(TableID: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableID);
        if AllObjWithCaption.FindFirst then;
        Error(StrSubstNo(RequestedRecordIsNotSupportedErr, AllObjWithCaption."Object Caption"));
    end;

    local procedure UpdateVendorTemplGlobalDimCode(GlobalDimCodeNo: Integer; VendorTemplCode: Code[20]; NewDimValue: Code[20])
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        if VendorTempl.Get(VendorTemplCode) then begin
            case GlobalDimCodeNo of
                1:
                    VendorTempl."Global Dimension 1 Code" := NewDimValue;
                2:
                    VendorTempl."Global Dimension 2 Code" := NewDimValue;
            end;
            VendorTempl.Modify(true);
        end;
    end;

    local procedure UpdateCustomerTemplGlobalDimCode(GlobalDimCodeNo: Integer; CustomerTemplCode: Code[20]; NewDimValue: Code[20])
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        if CustomerTempl.Get(CustomerTemplCode) then begin
            case GlobalDimCodeNo of
                1:
                    CustomerTempl."Global Dimension 1 Code" := NewDimValue;
                2:
                    CustomerTempl."Global Dimension 2 Code" := NewDimValue;
            end;
            CustomerTempl.Modify(true);
        end;
    end;

    local procedure UpdateItemTemplGlobalDimCode(GlobalDimCodeNo: Integer; ItemTemplCode: Code[20]; NewDimValue: Code[20])
    var
        ItemTempl: Record "Item Templ.";
    begin
        if ItemTempl.Get(ItemTemplCode) then begin
            case GlobalDimCodeNo of
                1:
                    ItemTempl."Global Dimension 1 Code" := NewDimValue;
                2:
                    ItemTempl."Global Dimension 2 Code" := NewDimValue;
            end;
            ItemTempl.Modify(true);
        end;
    end;

    local procedure UpdateEmployeeTemplGlobalDimCode(GlobalDimCodeNo: Integer; EmployeeTemplCode: Code[20]; NewDimValue: Code[20])
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if EmployeeTempl.Get(EmployeeTemplCode) then begin
            case GlobalDimCodeNo of
                1:
                    EmployeeTempl."Global Dimension 1 Code" := NewDimValue;
                2:
                    EmployeeTempl."Global Dimension 2 Code" := NewDimValue;
            end;
            EmployeeTempl.Modify(true);
        end;
    end;
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(DefaultDimension: Record "Default Dimension"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGLAccGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; GLAccNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; ItemNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGrGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; ResGrNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; ResNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateJobGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; JobNo: Code[20]; NewDimValue: Code[20])
    begin
    end;
}

