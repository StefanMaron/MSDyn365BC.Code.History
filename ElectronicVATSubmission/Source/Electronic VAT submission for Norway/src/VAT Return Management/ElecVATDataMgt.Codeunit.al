codeunit 10683 "Elec. VAT Data Mgt."
{
    var
        InputVATDeductibleDomesticTxt: Label 'Input VAT deduct. (domestic)', Comment = 'Fradragsberettiget innenlands inng+�ende merverdiavgift';
        InputVATDeductiblePayedOnImportTxt: Label 'Input VAT deduct. (payed on import)', Comment = 'Fradragsberettiget innf++rselsmerverdiavgift';
        OutputVATTxt: Label 'Output VAT', Comment = 'Utg+�ende merverdiavgift';
        DomesticSalesReverseChargeTxt: Label 'Domestic sales of reverce charge /VAT obligation', Comment = 'Innenlandsk omsetning med omvendt avgiftplikt';
        NotLiableToVATTreatmentTxt: Label 'Not liable to VAT treatment, turnover outside the scope of the VAT legislation', Comment = 'Omsetning utenfor merverdiavgiftsloven';
        ExportOfGoodsAndServicesTxt: Label 'Export of goods and services', Comment = 'Utf++rsel av varer og tjenester';
        ImportationOfGoodsVATDeductibleTxt: Label 'Importation of goods, VAT deduct.', Comment = 'Grunnlag innf++rsel av varer med fradragsrett for innf++rselsmerverdiavgift';

        ImportationOfGoodsWithoutDeductionOfVATTxt: Label 'Importation of goods, without deduction of VAT', Comment = 'Grunnlag innf++rsel av varer uten fradragsrett for innf++rselsmerverdiavgift';
        ImportationOfGoodsNotApplicableForVATTxt: Label 'Importation of goods, not applicable for VAT', Comment = 'Grunnlag innf++rsel av varer som det ikke skal beregnes merverdiavgift av';
        ServicesPurchasedFromAbroadVATDeductibleTxt: Label 'Services purchased from abroad, VAT deduct.', Comment = 'Tjenester kj++pt fra utlandet med fradragsrett for merverdiavgift';
        ServicesPurchasedFromAbroadWithoutVATDeductionTxt: Label 'Services purchased from abroad, without deduction of VAT', Comment = 'Tjenester kj++pt fra utlandet uten fradragsrett for merverdiavgift';
        PurchaseOfEmissionsTradingOrGoldVATDeductibleTxt: Label 'Purchase of emissions trading or gold, VAT deduct.', Comment = 'Kj++p av klimakvoter eller gull med fradragsrett for merverdiavgift';
        PurchaseOfEmissionsTradingOrGoldWithoutVATDeductionTxt: Label 'Purchase of emissions trading or gold, without deduction of VAT', Comment = 'Kj++p av klimakvoter eller gull uten fradragsrett for merverdiavgift';
        VATStatementNameNotSpecifiedErr: Label 'VAT statement template or VAT statement name has not been specified.';
        VATStatementWithNameAlreadyExistsErr: Label 'VAT statement %1 already exists. Specify another name.', Comment = '%1 = name of the VAT statement';

        NewVATStatementNameDescriptionLbl: Label 'VAT statement for electronic VAT submission';
        VATRatesForReportingHaveBeenSetMsg: Label 'The actual VAT rates for reporting have been assigned to VAT codes.';

    procedure GetMissingVATCodes(var TempMissingVATCode: Record "VAT Code" temporary) MissedCodesExist: Boolean
    var
        TempRequiredVATCode: Record "VAT Code" temporary;
        VATCode: Record "VAT Code";
    begin
        TempMissingVATCode.Reset();
        TempMissingVATCode.DeleteAll();
        GetRequiredVATCodes(TempRequiredVATCode);
        TempRequiredVATCode.FindSet();
        repeat
            if not VATCode.Get(TempRequiredVATCode.Code) then begin
                TempMissingVATCode := TempRequiredVATCode;
                TempMissingVATCode.Insert();
                MissedCodesExist := true;
            end;
        until TempRequiredVATCode.Next() = 0;
        exit(MissedCodesExist)
    end;

    procedure AddVATCodes(var TempVATCode: Record "VAT Code" temporary)
    var
        VATCode: Record "VAT Code";
    begin
        if not TempVATCode.FindSet() then
            exit;

        repeat
            if not VATCode.Get(TempVATCode.Code) then begin
                VATCode := TempVATCode;
                VATCode.Insert(true);
            end;
        until TempVATCode.Next() = 0;
    end;

    procedure CreateVATStatement(VATStatementTemplateName: Code[10]; NewVATStatementName: Code[10])
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        if (VATStatementTemplateName = '') or (NewVATStatementName = '') then
            error(VATStatementNameNotSpecifiedErr);
        if VATStatementName.Get(NewVATStatementName) then
            Error(VATStatementWithNameAlreadyExistsErr);
        VATStatementName."Statement Template Name" := VATStatementTemplateName;
        VATStatementName.Name := NewVATStatementName;
        VATStatementName.Description := NewVATStatementNameDescriptionLbl;
        VATStatementName.Insert(true);
        CreateVATStatementLines(VATStatementName);
    end;

    procedure SetVATRatesForReportingForVATCodes()
    var
        TempRequiredVATCode: Record "VAT Code" temporary;
        VATCode: Record "VAT Code";
    begin
        GetRequiredVATCodes(TempRequiredVATCode);
        TempRequiredVATCode.FindSet();
        repeat
            if VATCode.Get(TempRequiredVATCode.Code) then begin
                VATCode."VAT Rate For Reporting" := TempRequiredVATCode."VAT Rate For Reporting";
                VATCode."Report VAT Rate" := TempRequiredVATCode."Report VAT Rate";
                VATCode.Modify();
            end;
        until TempRequiredVATCode.Next() = 0;
        if GuiAllowed() then
            Message(VATRatesForReportingHaveBeenSetMsg);
    end;

    procedure IsReverseChargeVATCode(VATCode: Code[10]): Boolean
    begin
        exit(VATCode in ['81', '83', '86', '88', '91'])
    end;

    local procedure CreateVATStatementLines(VATStatementName: Record "VAT Statement Name")
    var
        TempRequiredVATCode: Record "VAT Code" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        VATStatementLine: Record "VAT Statement Line";
        AmountRowNo: Integer;
        RowTotalingFilter: Text[50];
        RowNo: Text[10];
        BoxNo: Text[30];
        LineNo: Integer;
        SetupCount: Integer;
        CalculateWith: Option;
    begin
        GetRequiredVATCodes(TempRequiredVATCode);
        TempRequiredVATCode.FindSet();
        repeat
            TempVATPostingSetup.Reset();
            TempVATPostingSetup.DeleteAll();
            VATPostingSetup.Reset();
            VATPostingSetup.SetRange("Sales SAF-T Standard Tax Code", TempRequiredVATCode.Code);
            CopyVATPostingSetupToTempVATPostingSetup(TempVATPostingSetup, VATPostingSetup);
            VATPostingSetup.Reset();
            VATPostingSetup.SetRange("Purch. SAF-T Standard Tax Code", TempRequiredVATCode.Code);
            CopyVATPostingSetupToTempVATPostingSetup(TempVATPostingSetup, VATPostingSetup);
            if TempVATPostingSetup.FindSet() then begin
                AmountRowNo := 0;
                RowTotalingFilter := '';
                SetupCount := TempVATPostingSetup.Count();
                if IsReverseChargeVATCode(TempRequiredVATCode.Code) then
                    CalculateWith := VATStatementLine."Calculate with"::Sign
                else
                    CalculateWith := VATStatementLine."Calculate with"::"Opposite Sign";
                repeat
                    RowNo := TempRequiredVATCode.Code;
                    If (SetupCount > 1) or ((TempVATPostingSetup."Sales SAF-T Standard Tax Code" <> '') and (TempVATPostingSetup."Purch. SAF-T Standard Tax Code" <> '')) then
                        BoxNo := ''
                    else
                        BoxNo := TempRequiredVATCode.Code;
                    if TempVATPostingSetup."Sales SAF-T Standard Tax Code" <> '' then begin
                        LineNo += 10000;
                        AmountRowNo += 1;
                        if BoxNo = '' then
                            RowNo += '-' + FOrmat(AmountRowNo);
                        CreateVATEntryTotalingLine(
                            VATStatementLine, VATStatementName, RowNo, BoxNo, TempRequiredVATCode.Description, TempVATPostingSetup,
                            VATStatementLine."Gen. Posting Type"::Sale, LineNo, CalculateWith);
                        AddToFilter(RowTotalingFilter, VATStatementLine."Row No.");
                    end;
                    if TempVATPostingSetup."Purch. SAF-T Standard Tax Code" <> '' then begin
                        LineNo += 10000;
                        AmountRowNo += 1;
                        if BoxNo = '' then
                            RowNo += '-' + Format(AmountRowNo);
                        CreateVATEntryTotalingLine(
                            VATStatementLine, VATStatementName, RowNo, BoxNo, TempRequiredVATCode.Description, TempVATPostingSetup,
                            VATStatementLine."Gen. Posting Type"::Purchase, LineNo, CalculateWith);
                        AddToFilter(RowTotalingFilter, VATStatementLine."Row No.");
                    end;
                until TempVATPostingSetup.Next() = 0;
                if BoxNo = '' then begin
                    LineNo += 10000;
                    CreateRowTotalingLine(VATStatementName, TempRequiredVATCode.Code, TempRequiredVATCode.Description, LineNo, RowTotalingFilter);
                end;
            end;
        until TempRequiredVATCode.Next() = 0;
    end;

    local procedure AddToFilter(var Filter: Text[50]; Value: Text)
    begin
        if Filter <> '' then
            Filter += '|';
        Filter += Value;
    end;

    local procedure CopyVATPostingSetupToTempVATPostingSetup(var TempVATPostingSetup: Record "VAT Posting Setup" temporary; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        if not VATPostingSetup.FindSet() then
            exit;
        repeat
            TempVATPostingSetup := VATPostingSetup;
            if not TempVATPostingSetup.Insert() then;
        until VATPostingSetup.Next() = 0;
    end;

    local procedure CreateVATEntryTotalingLine(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; RowNo: Code[10]; BoxNo: Text[30]; Description: Text[100]; VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type"; LineNo: Integer; CalculateWith: Option)
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.Validate("Statement Name", VATStatementName.Name);
        VATStatementLine.Validate("Line No.", LineNo);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate("Box No.", BoxNo);
        VATStatementLine.Validate(Description, Description);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Gen. Posting Type", GenPostingType);
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Validate("Calculate with", CalculateWith);
        VATStatementLine.Insert(true);
    end;

    local procedure CreateRowTotalingLine(VATStatementName: Record "VAT Statement Name"; VATCode: Code[10]; Description: Text[100]; LineNo: Integer; RowTotalingFilter: Text[50])
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.Validate("Statement Name", VATStatementName.Name);
        VATStatementLine.Validate("Line No.", LineNo);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"Row Totaling");
        VATStatementLine.Validate("Row No.", VATCode);
        VATStatementLine.Validate("Box No.", VATStatementLine."Row No.");
        VATStatementLine.Validate(Description, Description);
        VATStatementLine.Validate("Row Totaling", RowTotalingFilter);
        VATStatementLine.Insert(true);
    end;

    local procedure GetRequiredVATCodes(var TempRequiredVATCode: Record "VAT Code" temporary)
    begin
        InsertTempVATCode(TempRequiredVATCode, '1', InputVATDeductibleDomesticTxt, 0, false);
        InsertTempVATCode(TempRequiredVATCode, '3', OutputVATTxt, 25, true);
        InsertTempVATCode(TempRequiredVATCode, '5', DomesticSalesReverseChargeTxt, 0, true);
        InsertTempVATCode(TempRequiredVATCode, '6', NotLiableToVATTreatmentTxt, 0, true);
        InsertTempVATCode(TempRequiredVATCode, '11', InputVATDeductibleDomesticTxt, 0, false);
        InsertTempVATCode(TempRequiredVATCode, '12', InputVATDeductibleDomesticTxt, 0, false);
        InsertTempVATCode(TempRequiredVATCode, '13', InputVATDeductibleDomesticTxt, 0, false);
        InsertTempVATCode(TempRequiredVATCode, '14', InputVATDeductiblePayedOnImportTxt, 0, false);
        InsertTempVATCode(TempRequiredVATCode, '15', InputVATDeductiblePayedOnImportTxt, 0, false);
        InsertTempVATCode(TempRequiredVATCode, '31', OutputVATTxt, 15, true);
        InsertTempVATCode(TempRequiredVATCode, '32', OutputVATTxt, 11.11, true);
        InsertTempVATCode(TempRequiredVATCode, '33', OutputVATTxt, 12, true);
        InsertTempVATCode(TempRequiredVATCode, '51', DomesticSalesReverseChargeTxt, 0, true);
        InsertTempVATCode(TempRequiredVATCode, '52', ExportOfGoodsAndServicesTxt, 0, true);
        InsertTempVATCode(TempRequiredVATCode, '81', ImportationOfGoodsVATDeductibleTxt, 25, true);
        InsertTempVATCode(TempRequiredVATCode, '82', ImportationOfGoodsWithoutDeductionOfVATTxt, 25, true);
        InsertTempVATCode(TempRequiredVATCode, '83', ImportationOfGoodsVATDeductibleTxt, 15, true);
        InsertTempVATCode(TempRequiredVATCode, '84', ImportationOfGoodsWithoutDeductionOfVATTxt, 15, true);
        InsertTempVATCode(TempRequiredVATCode, '85', ImportationOfGoodsNotApplicableForVATTxt, 0, true);
        InsertTempVATCode(TempRequiredVATCode, '86', ServicesPurchasedFromAbroadVATDeductibleTxt, 25, true);
        InsertTempVATCode(TempRequiredVATCode, '87', ServicesPurchasedFromAbroadWithoutVATDeductionTxt, 25, true);
        InsertTempVATCode(TempRequiredVATCode, '88', ServicesPurchasedFromAbroadVATDeductibleTxt, 12, true);
        InsertTempVATCode(TempRequiredVATCode, '89', ServicesPurchasedFromAbroadWithoutVATDeductionTxt, 12, true);
        InsertTempVATCode(TempRequiredVATCode, '91', PurchaseOfEmissionsTradingOrGoldVATDeductibleTxt, 25, true);
        InsertTempVATCode(TempRequiredVATCode, '92', PurchaseOfEmissionsTradingOrGoldWithoutVATDeductionTxt, 25, true);
    end;

    local procedure InsertTempVATCode(var TempVATCode: Record "VAT Code"; Code: Code[10]; Description: Text; VATRateForReporting: Decimal; ReportVATRate: Boolean)
    begin
        TempVATCode.Code := Code;
        TempVATCode.Description := CopyStr(Description, 1, MaxStrLen(TempVATCode.Description));
        TempVATCode."VAT Rate For Reporting" := VATRateForReporting;
        TempVATCode."Report VAT Rate" := ReportVATRate;
        TempVATCode.Insert();
    end;
}
