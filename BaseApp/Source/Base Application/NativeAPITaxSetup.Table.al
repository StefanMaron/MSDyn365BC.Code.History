table 2850 "Native - API Tax Setup"
{
    Caption = 'Native - API Tax Setup';
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Total Tax Percentage"; Decimal)
        {
            Caption = 'Total Tax Percentage';
        }
        field(10; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(20; "VAT Percentage"; Decimal)
        {
            Caption = 'VAT Percentage';
        }
        field(21; "VAT Regulation Reference ID"; Guid)
        {
            Caption = 'VAT Regulation Reference ID';
        }
        field(22; "VAT Regulation Description"; Text[250])
        {
            Caption = 'VAT Regulation Description';
        }
        field(30; City; Text[30])
        {
            Caption = 'City';
        }
        field(31; "City Rate"; Decimal)
        {
            Caption = 'City Rate';

            trigger OnValidate()
            begin
                "Total Tax Percentage" := "City Rate" + "State Rate";
            end;
        }
        field(32; State; Code[2])
        {
            Caption = 'State';
        }
        field(33; "State Rate"; Decimal)
        {
            Caption = 'State Rate';

            trigger OnValidate()
            begin
                "Total Tax Percentage" := "City Rate" + "State Rate";
            end;
        }
        field(40; "GST or HST Code"; Code[10])
        {
            Caption = 'GST or HST Code';
        }
        field(41; "GST or HST Description"; Text[50])
        {
            Caption = 'GST or HST Description';
            Editable = false;
        }
        field(42; "GST or HST Rate"; Decimal)
        {
            Caption = 'GST or HST Rate';

            trigger OnValidate()
            begin
                "Total Tax Percentage" := "PST Rate" + "GST or HST Rate";
            end;
        }
        field(45; "PST Code"; Code[10])
        {
            Caption = 'PST Code';
        }
        field(46; "PST Description"; Text[50])
        {
            Caption = 'PST Description';
            Editable = false;
        }
        field(47; "PST Rate"; Decimal)
        {
            Caption = 'PST Rate';

            trigger OnValidate()
            begin
                "Total Tax Percentage" := "PST Rate" + "GST or HST Rate";
            end;
        }
        field(100; Default; Boolean)
        {
            Caption = 'Default';

            trigger OnValidate()
            begin
                if xRec.Default and (not Default) then
                    Error(OneValueMustBeDefaultErr);
            end;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
        }
        field(9600; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Sales Tax,VAT', Locked = true;
            OptionMembers = "Sales Tax",VAT;
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

    trigger OnDelete()
    begin
        DeleteRecord;
    end;

    var
        RecordMustBeTemporaryErr: Label 'Tax Group Entity must be used as a temporary record.';
        OneValueMustBeDefaultErr: Label 'One value must be default. To remove default select different entry as default.';
        CannotDeleteSetupErr: Label 'You cannot remove the tax setup.';
        CannotRemoveDefaultTaxAreaErr: Label 'You cannot remove the default tax area.';

    procedure LoadSetupRecords()
    var
        TempTaxAreaBuffer: Record "Tax Area Buffer" temporary;
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        if not TempTaxAreaBuffer.LoadRecords then
            exit;

        LoadFromTaxArea(TempTaxAreaBuffer);
    end;

    procedure ReloadRecord()
    var
        TempTaxAreaBuffer: Record "Tax Area Buffer" temporary;
        TempTaxGroupBuffer: Record "Tax Group Buffer" temporary;
        CurrentId: Guid;
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        CurrentId := Id;

        case Type of
            Type::"Sales Tax":
                begin
                    Clear(Rec);
                    DeleteAll;

                    if not TempTaxAreaBuffer.LoadRecords then
                        exit;

                    if not TempTaxAreaBuffer.Get(CurrentId) then
                        exit;

                    LoadFromTaxArea(TempTaxAreaBuffer);
                    SetRange(Id, CurrentId);
                    FindFirst;
                end;
            Type::VAT:
                begin
                    Clear(Rec);
                    DeleteAll;

                    if not TempTaxGroupBuffer.LoadRecords then
                        exit;

                    if not TempTaxGroupBuffer.Get(CurrentId) then
                        exit;

                    LoadFromTaxGroup(TempTaxGroupBuffer);
                    Insert;
                    SetRange(Id, CurrentId);
                    FindFirst;
                end;
        end;
    end;

    local procedure LoadFromTaxArea(var TempTaxAreaBuffer: Record "Tax Area Buffer" temporary)
    var
        TaxAreaBuffer: Record "Tax Area Buffer";
    begin
        case TempTaxAreaBuffer.Type of
            TempTaxAreaBuffer.Type::VAT:
                LoadVATSettings;
            TaxAreaBuffer.Type::"Sales Tax":
                OnLoadSalesTaxSettings(Rec, TempTaxAreaBuffer);
        end;
    end;

    procedure SaveChanges(var PreviousNativeAPITaxSetup: Record "Native - API Tax Setup")
    begin
        case Type of
            Type::VAT:
                SaveVATSettings(PreviousNativeAPITaxSetup);
            Type::"Sales Tax":
                OnSaveSalesTaxSettings(Rec);
        end;
    end;

    procedure DeleteRecord()
    var
        TaxArea: Record "Tax Area";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PreventDelete: Boolean;
    begin
        if Default then
            Error(CannotRemoveDefaultTaxAreaErr);

        OnCanDeleteTaxSetup(PreventDelete, Rec);

        if GeneralLedgerSetup.UseVat or PreventDelete then
            Error(CannotDeleteSetupErr);

        if TaxArea.Get(Code) then
            TaxArea.Delete(true);
    end;

    local procedure LoadVATSettings()
    var
        TempTaxGroupBuffer: Record "Tax Group Buffer" temporary;
    begin
        if not TempTaxGroupBuffer.LoadRecords then
            exit;

        repeat
            Clear(Rec);
            LoadFromTaxGroup(TempTaxGroupBuffer);
            Insert;
        until TempTaxGroupBuffer.Next = 0;
    end;

    local procedure LoadFromTaxGroup(var TempTaxGroupBuffer: Record "Tax Group Buffer" temporary)
    var
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        O365TemplateManagement: Codeunit "O365 Template Management";
    begin
        TransferFields(TempTaxGroupBuffer, true);
        "Last Modified Date Time" := TempTaxGroupBuffer."Last Modified DateTime";

        if not VATPostingSetup.Get(O365TemplateManagement.GetDefaultVATBusinessPostingGroup, Code) then
            exit;

        "VAT Percentage" := VATPostingSetup."VAT %";
        Default := Code = O365TemplateManagement.GetDefaultVATProdPostingGroup;

        // VAT Regulation Reference = Vat clause
        if not VATClause.Get(VATPostingSetup."VAT Clause Code") then begin
            VATClause.Init;
            VATClause.Code := Code;
            VATClause.Insert;
            VATPostingSetup.Validate("VAT Clause Code", Code);
            VATPostingSetup.Modify(true);
        end;

        "VAT Regulation Reference ID" := VATClause.Id;
        "VAT Regulation Description" := VATClause.Description;
    end;

    local procedure SaveVATSettings(var PreviousNativeAPITaxSetup: Record "Native - API Tax Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365TemplateManagement: Codeunit "O365 Template Management";
    begin
        if Default then
            O365TemplateManagement.SetDefaultVATProdPostingGroup(Code);

        UpdateVATClause(PreviousNativeAPITaxSetup);
        UpdateVATPercentage(PreviousNativeAPITaxSetup);

        if Description <> PreviousNativeAPITaxSetup.Description then begin
            VATProductPostingGroup.Get(Code);
            VATProductPostingGroup.Validate(Description, Description);
            VATProductPostingGroup.Modify(true);
        end;
    end;

    local procedure UpdateVATClause(var PreviousNativeAPITaxSetup: Record "Native - API Tax Setup")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        O365TemplateManagement: Codeunit "O365 Template Management";
    begin
        VATClause.SetRange(Id, "VAT Regulation Reference ID");
        VATClause.FindFirst;

        if PreviousNativeAPITaxSetup."VAT Regulation Reference ID" <> "VAT Regulation Reference ID" then begin
            VATPostingSetup.Get(O365TemplateManagement.GetDefaultVATBusinessPostingGroup, Code);
            VATPostingSetup.Validate("VAT Clause Code", VATClause.Code);
            VATPostingSetup.Modify(true);
        end;

        if VATClause.Description <> "VAT Regulation Description" then begin
            VATClause.Validate(Description, "VAT Regulation Description");
            VATClause.Modify(true);
        end;
    end;

    local procedure UpdateVATPercentage(var PreviousNativeAPITaxSetup: Record "Native - API Tax Setup")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        O365TemplateManagement: Codeunit "O365 Template Management";
    begin
        if PreviousNativeAPITaxSetup."VAT Percentage" <> "VAT Percentage" then begin
            VATPostingSetup.Get(O365TemplateManagement.GetDefaultVATBusinessPostingGroup, Code);
            VATPostingSetup.Validate("VAT %", "VAT Percentage");
            VATPostingSetup.Modify(true);

            SalesLine.SetRange("VAT Prod. Posting Group", Code);
            if SalesLine.FindSet then
                repeat
                    SalesLine.Validate("VAT Prod. Posting Group");
                    SalesLine.Modify(true);
                until SalesLine.Next = 0;
        end;
    end;

    procedure GetTaxAreaDisplayName(TaxAreaId: Guid): Text
    var
        TaxArea: Record "Tax Area";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if IsNullGuid(TaxAreaId) then
            exit;

        if GeneralLedgerSetup.UseVat then begin
            VATBusinessPostingGroup.SetRange(Id, TaxAreaId);
            if not VATBusinessPostingGroup.FindFirst then
                exit;

            exit(VATBusinessPostingGroup.Description);
        end;

        TaxArea.SetRange(Id, TaxAreaId);
        if not TaxArea.FindFirst then
            exit;

        exit(TaxArea.GetDescriptionInCurrentLanguage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadSalesTaxSettings(var NativeAPITaxSetup: Record "Native - API Tax Setup"; var TempTaxAreaBuffer: Record "Tax Area Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveSalesTaxSettings(var NewNativeAPITaxSetup: Record "Native - API Tax Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanDeleteTaxSetup(var PreventDeletion: Boolean; var NativeAPITaxSetup: Record "Native - API Tax Setup")
    begin
    end;
}

