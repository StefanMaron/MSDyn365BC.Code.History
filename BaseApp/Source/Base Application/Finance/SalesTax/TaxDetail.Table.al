namespace Microsoft.Finance.SalesTax;

table 322 "Tax Detail"
{
    Caption = 'Tax Detail';

    fields
    {
        field(1; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Jurisdiction";
        }
        field(2; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(3; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            NotBlank = false;
            OptionCaption = 'Sales and Use Tax,Excise Tax,Sales Tax Only,Use Tax Only';
            OptionMembers = "Sales and Use Tax","Excise Tax","Sales Tax Only","Use Tax Only";
        }
        field(4; "Maximum Amount/Qty."; Decimal)
        {
            Caption = 'Maximum Amount/Qty.';
            DecimalPlaces = 2 : 2;
            MinValue = 0;
        }
        field(5; "Tax Below Maximum"; Decimal)
        {
            Caption = 'Tax Below Maximum';
            DecimalPlaces = 1 : 4;
            MinValue = 0;
        }
        field(6; "Tax Above Maximum"; Decimal)
        {
            Caption = 'Tax Above Maximum';
            DecimalPlaces = 1 : 4;
            MinValue = 0;
        }
        field(7; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
        }
        field(8; "Calculate Tax on Tax"; Boolean)
        {
            Caption = 'Calculate Tax on Tax';
            Editable = false;
        }
        field(10010; "Expense/Capitalize"; Boolean)
        {
            Caption = 'Expense/Capitalize';
        }
    }

    keys
    {
        key(Key1; "Tax Jurisdiction Code", "Tax Group Code", "Tax Type", "Effective Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get("Tax Jurisdiction Code");
        "Calculate Tax on Tax" := TaxJurisdiction."Calculate Tax on Tax";
        if "Tax Type" <> "Tax Type"::"Excise Tax" then begin
            PrepareForCheckTaxType(Rec);
            if TaxDetailTemp.Count > 0 then
                if not CheckTaxType(Rec) then
                    Error(Text001);
        end;
    end;

    trigger OnRename()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get("Tax Jurisdiction Code");
        "Calculate Tax on Tax" := TaxJurisdiction."Calculate Tax on Tax";
        if "Tax Type" <> "Tax Type"::"Excise Tax" then begin
            PrepareForCheckTaxType(Rec);
            if TaxDetailTemp.Get(xRec."Tax Jurisdiction Code", xRec."Tax Group Code", xRec."Tax Type", xRec."Effective Date") then
                TaxDetailTemp.Delete();
            if TaxDetailTemp.Count > 0 then
                if not CheckTaxType(Rec) then
                    Error(Text001);
        end;
    end;

    var
        SpecifyTaxMsg: Label 'Please specify a %1 first.', Comment = '%1=Tax Area Code or Tax Group Code';
        TaxDetailTemp: Record "Tax Detail" temporary;
        Text001: Label 'A tax detail already exists with the same tax jurisdiction, tax group, and tax type.';
        CannotChangeNonTaxableGroupCodeErr: Label 'You cannot change the rate for the non-taxable group.';

    procedure CheckTaxType(TaxDetailRec: Record "Tax Detail"): Boolean
    begin
        if TaxDetailRec."Tax Type" = TaxDetailRec."Tax Type"::"Sales and Use Tax" then
            TaxDetailTemp.SetFilter("Tax Type", '%1|%2', TaxDetailRec."Tax Type"::"Sales Tax Only",
              TaxDetailRec."Tax Type"::"Use Tax Only")
        else
            TaxDetailTemp.SetRange("Tax Type", TaxDetailRec."Tax Type"::"Sales and Use Tax");
        if TaxDetailTemp.FindFirst() then
            exit(false)
        else
            exit(true);
    end;

    procedure PrepareForCheckTaxType(TaxDetailRec: Record "Tax Detail")
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxDetailTemp.Reset();
        TaxDetailTemp.DeleteAll();
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxDetailRec."Tax Jurisdiction Code");
        TaxDetail.SetRange("Tax Group Code", TaxDetailRec."Tax Group Code");
        TaxDetail.SetRange("Effective Date", TaxDetailRec."Effective Date");
        if TaxDetail.FindSet() then
            repeat
                TaxDetailTemp.Init();
                TaxDetailTemp := TaxDetail;
                TaxDetailTemp.Insert();
            until TaxDetail.Next() = 0;
    end;

    local procedure ApplyCommonFilters(TaxJurisdictionCode: Code[20]; TaxGroupCode: Code[20]; TaxType: Option; EffectiveDate: Date)
    begin
        Reset();
        SetRange("Tax Jurisdiction Code", TaxJurisdictionCode);
        SetRange("Tax Group Code", TaxGroupCode);
        SetRange("Tax Type", TaxType);
        if EffectiveDate <> 0D then
            SetFilter("Effective Date", '<=%1', EffectiveDate);
    end;

    procedure ValidateTaxSetup(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; EffectiveDate: Date)
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        TaxSetup: Record "Tax Setup";
    begin
        TaxArea.Get(TaxAreaCode);
        TaxGroup.Get(TaxGroupCode);
        TaxSetup.Get();
        TaxAreaLine.SetRange("Tax Area", TaxArea.Code);
        if TaxAreaLine.FindSet() then
            repeat
                if TaxGroupCode <> TaxSetup."Non-Taxable Tax Group Code" then begin
                    ApplyCommonFilters(TaxAreaLine."Tax Jurisdiction Code", '', "Tax Type"::"Sales and Use Tax", EffectiveDate);
                    if not FindFirst() then
                        ApplyCommonFilters(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, "Tax Type"::"Sales and Use Tax", EffectiveDate);
                end else
                    ApplyCommonFilters(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, "Tax Type"::"Sales and Use Tax", EffectiveDate);
                if not FindFirst() then
                    SetNewTaxRate(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, "Tax Type"::"Sales and Use Tax", EffectiveDate, 0);
            until TaxAreaLine.Next() = 0;
    end;

    procedure GetSalesTaxRate(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; EffectiveDate: Date; TaxLiable: Boolean): Decimal
    var
        TaxAreaLine: Record "Tax Area Line";
        TotalTaxRate: Decimal;
    begin
        if not TaxLiable then
            exit(0);
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.FindSet() then
            repeat
                TotalTaxRate += GetTaxRate(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, "Tax Type"::"Sales and Use Tax", EffectiveDate);
            until TaxAreaLine.Next() = 0;
        exit(TotalTaxRate);
    end;

    procedure SetSalesTaxRate(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; NewTaxRate: Decimal; EffectiveDate: Date)
    var
        TaxSetup: Record "Tax Setup";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxJurisdiction2: Record "Tax Jurisdiction";
        TotalTaxRate: Decimal;
    begin
        if TaxGroupCode = '' then
            exit;
        if TaxSetup.Get() then
            if TaxSetup."Non-Taxable Tax Group Code" = TaxGroupCode then
                Error(CannotChangeNonTaxableGroupCodeErr);
        if NewTaxRate = GetSalesTaxRate(TaxAreaCode, TaxGroupCode, EffectiveDate, true) then
            exit;
        if TaxAreaCode = '' then begin
            Message(SpecifyTaxMsg, TaxAreaLine.FieldCaption("Tax Area"));
            exit;
        end;
        TotalTaxRate := 0;
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        TaxAreaLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
        if TaxAreaLine.FindSet() then
            repeat
                if TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code") then begin
                    TotalTaxRate += GetTaxRate(TaxJurisdiction.Code, TaxGroupCode, "Tax Type"::"Sales and Use Tax", EffectiveDate);
                    if TaxJurisdiction2.Code = '' then // the first
                        TaxJurisdiction2 := TaxJurisdiction
                    else
                        if TaxJurisdiction.Code <> TaxJurisdiction."Report-to Jurisdiction" then
                            TaxJurisdiction2 := TaxJurisdiction;
                end;
            until TaxAreaLine.Next() = 0;
        if TaxJurisdiction2.Code = '' then
            exit; // missing setup
        TotalTaxRate -= GetTaxRate(TaxJurisdiction2.Code, TaxGroupCode, "Tax Type"::"Sales and Use Tax", EffectiveDate);
        SetNewTaxRate(TaxJurisdiction2.Code, TaxGroupCode, "Tax Type"::"Sales and Use Tax", EffectiveDate, NewTaxRate - TotalTaxRate);
    end;

    procedure SetSalesTaxRateDetailed(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; NewCityRate: Decimal; NewCountyRate: Decimal; NewStateRate: Decimal; EffectiveDate: Date)
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxJurisDictionCodes: array[3] of Code[10];
        i: Integer;
    begin
        if TaxAreaCode = '' then begin
            Message(SpecifyTaxMsg, TaxAreaLine.FieldCaption("Tax Area"));
            exit;
        end;
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        TaxAreaLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
        if TaxAreaLine.FindSet() then
            repeat
                if TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code") then begin
                    i += 1;
                    if i <= 3 then
                        TaxJurisDictionCodes[i] := TaxJurisdiction.Code;
                end;
            until (TaxAreaLine.Next() = 0) or (i = 3);
        if i = 0 then
            exit;
        if i < 3 then begin
            NewStateRate += NewCountyRate;
            NewCountyRate := 0;
        end;
        if i < 2 then begin
            NewStateRate += NewCityRate;
            NewCityRate := 0;
        end;
        case i of
            1:
                SetNewTaxRate(TaxJurisDictionCodes[1], TaxGroupCode, "Tax Type"::"Sales Tax Only", EffectiveDate, NewStateRate);
            2:
                begin
                    SetNewTaxRate(TaxJurisDictionCodes[1], TaxGroupCode, "Tax Type"::"Sales Tax Only", EffectiveDate, NewCityRate);
                    SetNewTaxRate(TaxJurisDictionCodes[2], TaxGroupCode, "Tax Type"::"Sales Tax Only", EffectiveDate, NewStateRate);
                end;
            3:
                begin
                    SetNewTaxRate(TaxJurisDictionCodes[1], TaxGroupCode, "Tax Type"::"Sales Tax Only", EffectiveDate, NewCityRate);
                    SetNewTaxRate(TaxJurisDictionCodes[2], TaxGroupCode, "Tax Type"::"Sales Tax Only", EffectiveDate, NewCountyRate);
                    SetNewTaxRate(TaxJurisDictionCodes[3], TaxGroupCode, "Tax Type"::"Sales Tax Only", EffectiveDate, NewStateRate);
                end;
        end;
    end;

    local procedure GetTaxRate(TaxJurisdictionCode: Code[20]; TaxGroupCode: Code[20]; TaxType: Option; EffectiveDate: Date): Decimal
    begin
        ApplyCommonFilters(TaxJurisdictionCode, TaxGroupCode, TaxType, EffectiveDate);
        if FindLast() then
            exit("Tax Below Maximum");
        exit(0);
    end;

    local procedure SetNewTaxRate(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option; EffectiveDate: Date; NewTaxRate: Decimal)
    begin
        ApplyCommonFilters(TaxJurisdictionCode, TaxGroupCode, TaxType, EffectiveDate);
        SetRange("Effective Date", EffectiveDate);
        LockTable();
        if not FindLast() then begin
            Init();
            "Tax Jurisdiction Code" := TaxJurisdictionCode;
            "Tax Group Code" := TaxGroupCode;
            "Tax Type" := TaxType;
            "Effective Date" := EffectiveDate;
            Insert();
        end;
        "Tax Below Maximum" := NewTaxRate;
        Modify();
    end;
}

