table 352 "Default Dimension"
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
                if not TempAllObjWithCaption.Find() then
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
                if RecRef.IsEmpty() then
                    Error(NoValidateErr, "No.", RecRef.Caption);
                RecRef.Close();
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
                UpdateDimensionId();
                if "Dimension Code" <> xRec."Dimension Code" then
                    Validate("Dimension Value Code", '');
            end;
        }
        field(4; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Dimension Code"),
                                                         Blocked = CONST(false));

            trigger OnValidate()
            begin
                CheckDimensionValue("Dimension Code", "Dimension Value Code");
                UpdateDimensionValueId();
            end;
        }
        field(5; "Value Posting"; Enum "Default Dimension Value Posting Type")
        {
            Caption = 'Value Posting';

            trigger OnValidate()
            var
                DimValuePerAccount: Record "Dim. Value per Account";
            begin
                if "Value Posting" = "Value Posting"::"No Code" then
                    TestField("Dimension Value Code", '');
                if not IsTemporary() then
                    ClearAllowedValuesFilter(DimValuePerAccount);
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
        field(10; "Allowed Values Filter"; Text[250])
        {
            Caption = 'Allowed Values Filter';

            trigger OnValidate()
            var
                DimValuePerAccount: Record "Dim. Value per Account";
            begin
                TestField("Dimension Code");
                TestField("Value Posting", "Default Dimension Value Posting Type"::"Code Mandatory");
                if not IsTemporary() then
                    UpdateDimValuesPerAccountFromAllowedValuesFilter(DimValuePerAccount);
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
    var
        DimValuePerAccount: Record "Dim. Value per Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, DimMgt, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        if "Dimension Code" = GLSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", '');
        if "Dimension Code" = GLSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", '');
        DimMgt.DefaultDimOnDelete(Rec);

        DimValuePerAccount.SetRange("Table ID", "Table ID");
        DimValuePerAccount.SetRange("No.", "No.");
        DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
        DimValuePerAccount.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, DimMgt, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        if "Dimension Code" = GLSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", "Dimension Value Code");
        if "Dimension Code" = GLSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", "Dimension Value Code");
        DimMgt.DefaultDimOnInsert(Rec);
        UpdateParentId();
        UpdateParentType();
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Rec, DimMgt, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        if "Dimension Code" = GLSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", "Dimension Value Code");
        if "Dimension Code" = GLSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", "Dimension Value Code");
        DimMgt.DefaultDimOnModify(Rec);
    end;

    trigger OnRename()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRename(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Table ID" <> xRec."Table ID") or ("Dimension Code" <> xRec."Dimension Code") then
            Error(Text000, TableCaption);

        DimValuePerAccount.RenameNo("Table ID", xRec."No.", "No.", "Dimension Code");
    end;

    var
        GLSetup: Record "General Ledger Setup";
        DimMgt: Codeunit DimensionManagement;

        Text000: Label 'You can''t rename a %1.';
        DimensionIdDoesNotMatchADimensionErr: Label 'The "dimensionId" does not match to a Dimension.', Locked = true;
        DimensionValueIdDoesNotMatchADimensionValueErr: Label 'The "dimensionValueId" does not match to a Dimension Value.', Locked = true;
        DimensionIdMismatchErr: Label 'The "dimensionId" and "dimensionValueId" match to different Dimension records.', Locked = true;
        ParentIdDoesNotMatchAnIntegrationRecordErr: Label 'The "parenteId" does not match to any entity.', Locked = true;
        RequestedRecordIsNotSupportedErr: Label 'Images are not supported for requested entity - %1.', Locked = true;
        NoValidateErr: Label 'The field No. of table Default Dimension contains a value (%1) that cannot be found in the related table (%2).', Comment = '%1 - a master table record key value; %2 - table caption. ';
        MultipleParentsFoundErr: Label 'Multiple parents have been found for the specified criteria.';
        ParentNotFoundErr: Label 'Parent is not found.';
        InvalidAllowedValuesFilterErr: Label 'There are no dimension values for allowed values filter %1.', Comment = '%1 - allowed values filter';
        DefaultDimValueErr: Label 'You cannot block dimension value %1 because it is a default value for %2, %3.', Comment = '%1 = dimension value code and %2- table name, %3 - account number';

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

        CurrTableID := 0;
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

    procedure UpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20])
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
            OnUpdateGLAccGlobalDimCodeOnBeforeGLAccModify(GLAcc, NewDimValue, GlobalDimCodeNo);
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
                else
                    OnUpdateCustGlobalDimCodeOnCaseElse(GlobalDimCodeNo, CustNo, NewDimValue);
            end;
            OnUpdateCustGlobalDimCodeOnBeforeCustModify(Cust, NewDimValue, GlobalDimCodeNo);
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
                else
                    OnUpdateVendGlobalDimCodeOnCaseElse(GlobalDimCodeNo, VendNo, NewDimValue);
            end;
            OnUpdateVendGlobalDimCodeOnBeforeVendModify(Vend, NewDimValue, GlobalDimCodeNo);
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
            OnUpdateItemGlobalDimCodeOnBeforeItemModify(Item, NewDimValue, GlobalDimCodeNo);
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
            OnUpdateResGrGlobalDimCodeOnBeforeResGrModify(ResGr, NewDimValue, GlobalDimCodeNo);
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
            OnUpdateResGlobalDimCodeOnBeforeResModify(Res, NewDimValue, GlobalDimCodeNo);
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
            OnUpdateJobGlobalDimCodeOnBeforeJobModify(Job, NewDimValue, GlobalDimCodeNo);
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
                else
                    OnUpdateBankGlobalDimCodeCaseElse(GlobalDimCodeNo, BankAccNo, NewDimValue);
            end;
            OnUpdateBankGlobalDimCodeOnBeforeBankModify(BankAcc, NewDimValue, GlobalDimCodeNo);
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
                else
                    OnUpdateEmpoyeeGlobalDimCodeCaseElse(GlobalDimCodeNo, EmployeeNo, NewDimValue);
            end;
            OnUpdateEmployeeGlobalDimCodeOnBeforeEmployeeModify(Employee, NewDimValue, GlobalDimCodeNo);
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
                else
                    OnUpdateFAGlobalDimCodeCaseElse(GlobalDimCodeNo, FANo, NewDimValue);
            end;
            OnUpdateFAGlobalDimCodeOnBeforeFAModify(FA, NewDimValue, GlobalDimCodeNo);
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
                else
                    OnUpdateInsuranceGlobalDimCodeCaseElse(GlobalDimCodeNo, InsuranceNo, NewDimValue);
            end;
            OnUpdateInsuranceGlobalDimCodeOnBeforeInsuranceModify(Insurance, NewDimValue, GlobalDimCodeNo);
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
                else
                    OnUpdateRespCenterGlobalDimCodeCaseElse(GlobalDimCodeNo, RespCenterNo, NewDimValue);
            end;
            OnUpdateRespCenterGlobalDimCodeOnBeforeRespCenterModify(RespCenter, NewDimValue, GlobalDimCodeNo);
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
                else
                    OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo, WorkCenterNo, NewDimValue);
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
                else
                    OnUpdateSalesPurchGlobalDimCodeCaseElse(GlobalDimCodeNo, SalespersonPurchaserNo, NewDimValue);
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
                else
                    OnUpdateCampaignGlobalDimCodeCaseElse(GlobalDimCodeNo, CampaignNo, NewDimValue);
            end;
            Campaign.Modify(true);
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
                else
                    OnUpdateNeutrPayGlobalDimCodeCaseElse(GlobalDimCodeNo, CFManualExpenseNo, NewDimValue);
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
                else
                    OnUpdateNeutrRevGlobalDimCodeCaseElse(GlobalDimCodeNo, CFManualRevenueNo, NewDimValue);
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
            Error(DimMgt.GetDimErr());
    end;

    local procedure CheckDimensionValue(DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        if not DimMgt.CheckDimValue(DimensionCode, DimensionValueCode) then
            Error(DimMgt.GetDimErr());
        if "Value Posting" = "Value Posting"::"No Code" then
            TestField("Dimension Value Code", '');
        CheckDimensionValueAllowedForAccount();
    end;

    local procedure CheckDimensionValueAllowedForAccount()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        if DimValuePerAccount.Get("Table ID", "No.", "Dimension Code", "Dimension Value Code") then
            if not DimValuePerAccount.Allowed then
                Error(DimMgt.GetNotAllowedDimValuePerAccount(Rec, "Dimension Value Code"));
    end;

    procedure ClearAllowedValuesFilter(var DimValuePerAccount: Record "Dim. Value per Account")
    begin
        if (xRec."Value Posting" = "Value Posting"::"Code Mandatory") and ("Value Posting" <> "Value Posting"::"Code Mandatory") then begin
            DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
            DimValuePerAccount.SetRange("Table ID", "Table ID");
            DimValuePerAccount.SetRange("No.", "No.");
            if not DimValuePerAccount.IsEmpty() then begin
                DimValuePerAccount.DeleteAll();
                "Allowed Values Filter" := '';
            end;
        end;
    end;

    [Obsolete('Replaced by CreateDimValuePerAccountFromDimValue(DimValue: Record "Dimension Value"; Allowed: Boolean)', '22.0')]
    procedure CreateDimValuePerAccountFromDimValue(DimValue: Record "Dimension Value")
    begin
        CreateDimValuePerAccountFromDimValue(DimValue, false);
    end;

    procedure CreateDimValuePerAccountFromDimValue(DimValue: Record "Dimension Value"; ShouldUpdateAllowed: Boolean)
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.Init();
        DimValuePerAccount."Dimension Code" := DimValue."Dimension Code";
        DimValuePerAccount."Dimension Value Code" := DimValue.Code;
        DimValuePerAccount."Table ID" := "Table ID";
        DimValuePerAccount."No." := "No.";
        if not ShouldUpdateAllowed then
            DimValuePerAccount.Allowed := false
        else
            DimValuePerAccount.Allowed := IncludedInAllowedValuesFilter(DimValuePerAccount);
        DimValuePerAccount.Insert();
    end;

    procedure IncludedInAllowedValuesFilter(DimValuePerAccount: Record "Dim. Value per Account"): Boolean
    var
        TempDimValuePerAccount: Record "Dim. Value per Account" temporary;
    begin
        TempDimValuePerAccount := DimValuePerAccount;
        TempDimValuePerAccount.Insert;

        TempDimValuePerAccount.SetRange("Table ID", DimValuePerAccount."Table ID");
        TempDimValuePerAccount.SetRange("No.", DimValuePerAccount."No.");
        TempDimValuePerAccount.SetRange("Dimension Code", DimValuePerAccount."Dimension Code");
        TempDimValuePerAccount.SetFilter("Dimension Value Code", "Allowed Values Filter");

        If not TempDimValuePerAccount.IsEmpty() then
            exit(true);
    end;

    procedure UpdateDimValuesPerAccountFromAllowedValuesFilter(var DimValuePerAccount: Record "Dim. Value per Account")
    begin
        if "Allowed Values Filter" = '' then begin
            DimValuePerAccount.SetRange("Table ID", "Table ID");
            DimValuePerAccount.SetRange("No.", "No.");
            DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
            DimValuePerAccount.DeleteAll();
            exit;
        end;

        DimMgt.SyncDimValuePerAccountWithDimValues(Rec);

        CheckDimensionValuesInFilter();

        SetDimValuesPerAccountByAllowedValuesFilter(DimValuePerAccount);

        if ("Dimension Value Code" <> '') and DimValuePerAccount.Get("Table ID", "No.", "Dimension Code", "Dimension Value Code") then
            if not DimValuePerAccount.Allowed then
                CheckDisallowedDimensionValue(DimValuePerAccount);
    end;

    local procedure SetDimValuesPerAccountByAllowedValuesFilter(var DimValuePerAccount: Record "Dim. Value per Account")
    begin
        DimValuePerAccount.Reset();
        DimValuePerAccount.SetRange("Table ID", "Table ID");
        DimValuePerAccount.SetRange("No.", "No.");
        DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
        DimValuePerAccount.ModifyAll(Allowed, false);
        DimValuePerAccount.SetFilter("Dimension Value Code", "Allowed Values Filter");
        DimValuePerAccount.ModifyAll(Allowed, true);
    end;

    local procedure CheckDimensionValuesInFilter()
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", "Dimension Code");
        DimensionValue.SetFilter(Code, "Allowed Values Filter");
        if DimensionValue.IsEmpty() then
            Error(InvalidAllowedValuesFilterErr, "Allowed Values Filter");
    end;

    procedure CheckDisallowedDimensionValue(DimValuePerAccount: Record "Dim. Value per Account")
    begin
        if "Dimension Value Code" = DimValuePerAccount."Dimension Value Code" then
            Error(DefaultDimValueErr, DimValuePerAccount."Dimension Value Code", DimValuePerAccount.GetTableCaption(), "No.");
    end;

    procedure UpdateDefaultDimensionAllowedValuesFilter()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
        AllowedValues: Text[250];
    begin
        AllowedValues := GetAllowedValuesFilter();
        if AllowedValues <> "Allowed Values Filter" then begin
            "Allowed Values Filter" := AllowedValues;
            if "Allowed Values Filter" = '' then begin
                DimValuePerAccount.SetRange("Table ID", "Table ID");
                DimValuePerAccount.SetRange("No.", "No.");
                DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
                DimValuePerAccount.DeleteAll();
            end else
                CheckDimensionValuesInFilter();
            Modify();
        end;
    end;

    procedure GetAllowedValuesFilter(): Text[250]
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        exit(CopyStr(GetFullAllowedValuesFilter(DimValuePerAccount), 1, MaxStrLen("Allowed Values Filter")));
    end;

    procedure GetFullAllowedValuesFilter(var DimValuePerAccount: Record "Dim. Value per Account"): Text
    var
        SelectionFilterMgt: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
        DimValuePerAccount.SetRange("Table ID", "Table ID");
        DimValuePerAccount.SetRange("No.", "No.");
        DimValuePerAccount.Setrange(Allowed, false);
        if DimValuePerAccount.IsEmpty() then
            exit('');
        DimMgt.CheckIfNoAllowedValuesSelected(DimValuePerAccount);
        RecRef.GetTable(DimValuePerAccount);
        exit(SelectionFilterMgt.GetSelectionFilter(RecRef, DimValuePerAccount.FieldNo("Dimension Value Code")));
    end;

    local procedure SetRangeToLastFieldInPrimaryKey(RecRef: RecordRef; Value: Code[20])
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
        FieldRef.SetRange(Value);

        OnAfterSetRangeToLastFieldInPrimaryKey(RecRef, Value, FieldRef);
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
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        ParentRecordRef: RecordRef;
        ParentRecordRefId: RecordId;
    begin
        if not GetRecordRefFromFilter(Id, ParentRecordRef) then
            Error(ParentIdDoesNotMatchAnIntegrationRecordErr);

        ParentRecordRefId := ParentRecordRef.RecordId;

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
        if Customer.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Customer);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        Vendor.SetFilter(SystemId, IDFilter);
        if Vendor.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Vendor);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        Employee.SetFilter(SystemId, IDFilter);
        if Employee.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Employee);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        exit(RecordFound);
    end;

    procedure UpdateParentType(): Boolean
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

    procedure UpdateParentId(): Boolean
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
        Modified := Modified or UpdateParentType();
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
        if AllObjWithCaption.FindFirst() then;
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
                else
                    OnUpdateVendorTemplGlobalDimCodeCaseElse(GlobalDimCodeNo, VendorTemplCode, NewDimValue);
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
                else
                    OnUpdateCustomerTemplGlobalDimCodeCaseElse(GlobalDimCodeNo, CustomerTemplCode, NewDimValue);
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
                else
                    OnUpdateItemTemplGlobalDimCodeCaseElse(GlobalDimCodeNo, ItemTemplCode, NewDimValue);
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
                else
                    OnUpdateEmployeeTemplGlobalDimCodeCaseElse(GlobalDimCodeNo, EmployeeTemplCode, NewDimValue);
            end;
            EmployeeTempl.Modify(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRangeToLastFieldInPrimaryKey(RecRef: RecordRef; Value: Code[20]; var FieldRef: FieldRef)
    begin
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
    local procedure OnBeforeOnDelete(var DefaultDimension: Record "Default Dimension"; var DimensionManagement: Codeunit DimensionManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var DefaultDimension: Record "Default Dimension"; var DimensionManagement: Codeunit DimensionManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var DefaultDimension: Record "Default Dimension"; var DimensionManagement: Codeunit DimensionManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRename(var DefaultDimension: Record "Default Dimension"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGLAccGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; GLAccNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGLAccGlobalDimCodeOnBeforeGLAccModify(var GLAcc: Record "G/L Account"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBankGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; BankAccNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBankGlobalDimCodeOnBeforeBankModify(var BankAccount: Record "Bank Account"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCampaignGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; CampaignNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; CustNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustGlobalDimCodeOnBeforeCustModify(var Customer: Record Customer; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomerTemplGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; CustomerTemplCode: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEmpoyeeGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; EmployeeNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEmployeeGlobalDimCodeOnBeforeEmployeeModify(var Employee: Record Employee; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEmployeeTemplGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; EmployeeTemplCode: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFAGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; FANo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFAGlobalDimCodeOnBeforeFAModify(var FixedAsset: Record "Fixed Asset"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInsuranceGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; InsuranceNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInsuranceGlobalDimCodeOnBeforeInsuranceModify(var Insurance: Record Insurance; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; ItemNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemGlobalDimCodeOnBeforeItemModify(var Item: Record Item; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemTemplGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; ItemTemplCode: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateJobGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; JobNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateJobGlobalDimCodeOnBeforeJobModify(var Job: Record Job; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateNeutrRevGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; CFManualRevenueNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateNeutrPayGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; CFManualExpenseNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGrGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; ResGrNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGrGlobalDimCodeOnBeforeResGrModify(var ResGr: Record "Resource Group"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; ResNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGlobalDimCodeOnBeforeResModify(var Resource: Record Resource; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRespCenterGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; RespCenterNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRespCenterGlobalDimCodeOnBeforeRespCenterModify(var RespCenter: Record "Responsibility Center"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesPurchGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; SalespersonPurchaserNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; VendNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendGlobalDimCodeOnBeforeVendModify(var Vend: Record Vendor; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorTemplGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; VendorTemplCode: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; WorkCenterNo: Code[20]; NewDimValue: Code[20])
    begin
    end;
}

