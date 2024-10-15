report 12460 "VAT Ledger Export"
{
    Caption = 'VAT Ledger Export';
    ProcessingOnly = true;

    dataset
    {
        dataitem(VATLedger; "VAT Ledger")
        {
            DataItemTableView = SORTING(Type, Code);
            dataitem(SalesVATLedgerLine; "VAT Ledger Line")
            {
                DataItemLink = Type = FIELD(Type), Code = FIELD(Code);
                DataItemTableView = SORTING(Type, Code, "Line No.") WHERE(Type = CONST(Sales), "Additional Sheet" = CONST(false));

                trigger OnAfterGetRecord()
                begin
                    LineNo += 1;
                    ExcelReportBuilderManager.AddSection('BODY');
                    ExportSalesVATLedgerLine(SalesVATLedgerLine);
                end;

                trigger OnPostDataItem()
                begin
                    if not AddSheet and (VATLedgerType = VATLedger.Type::Sales) then
                        ExportSalesVATLedgerLineTotals;
                end;

                trigger OnPreDataItem()
                begin
                    if AddSheet or (VATLedgerType = VATLedger.Type::Purchase) then
                        CurrReport.Break();

                    LineNo := 0;

                    case Sorting of
                        Sorting::"Document Date":
                            SetCurrentKey("Document Date");
                        Sorting::"Document No.":
                            SetCurrentKey("Document No.");
                        Sorting::"Customer No.":
                            SetCurrentKey("C/V No.");
                        else
                            SetCurrentKey("Real. VAT Entry Date");
                    end;
                end;
            }
            dataitem(PurchVATLedgerLine; "VAT Ledger Line")
            {
                DataItemLink = Type = FIELD(Type), Code = FIELD(Code);
                DataItemTableView = SORTING(Type, Code, "Line No.") WHERE(Type = CONST(Purchase), "Additional Sheet" = CONST(false));

                trigger OnAfterGetRecord()
                begin
                    LineNo += 1;
                    ExcelReportBuilderManager.AddSection('BODY');

                    ExportPurchVATLedgerLine(PurchVATLedgerLine, LineNo);
                end;

                trigger OnPostDataItem()
                begin
                    if AddSheet or (VATLedgerType = VATLedger.Type::Sales) then
                        CurrReport.Break();

                    ExportPurchVATLedgerLineTotals;
                end;

                trigger OnPreDataItem()
                begin
                    if AddSheet or (VATLedgerType = VATLedger.Type::Sales) then
                        CurrReport.Break();

                    LineNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not AddSheet then
                    ExportVATLedgerHeader;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Type, VATLedgerType);
                SetRange(Code, VATLedgerCode);
            end;
        }
        dataitem(SalesAddSheetPeriod; Date)
        {
            DataItemTableView = SORTING("Period Type", "Period Start");
            dataitem(SalesVATLedgerLineAddSheet; "VAT Ledger Line")
            {
                DataItemLink = Type = FIELD(Type), Code = FIELD(Code);
                DataItemLinkReference = VATLedger;
                DataItemTableView = SORTING(Type, Code, "Line No.") WHERE(Type = CONST(Sales), "Additional Sheet" = CONST(true));

                trigger OnAfterGetRecord()
                var
                    SalesInvHeader: Record "Sales Invoice Header";
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    CorrDocAddSheet: Boolean;
                begin
                    if SalesInvHeader.Get("Document No.") then
                        CorrDocAddSheet := SalesInvHeader."Additional VAT Ledger Sheet";
                    if SalesCrMemoHeader.Get("Document No.") then
                        CorrDocAddSheet := SalesCrMemoHeader."Additional VAT Ledger Sheet";

                    if CorrDocAddSheet then
                        "Document Date" := "Corr. VAT Entry Posting Date";

                    LineNo += 1;
                    ExcelReportBuilderManager.AddSection('BODY');
                    ExportSalesVATLedgerLine(SalesVATLedgerLineAddSheet);
                end;

                trigger OnPostDataItem()
                begin
                    ExportSalesVATLedgerLineTotals;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Corr. VAT Entry Posting Date", SalesAddSheetPeriod."Period Start", SalesAddSheetPeriod."Period End");

                    LineNo := 0;

                    case Sorting of
                        Sorting::"Document Date":
                            SetCurrentKey("Document Date");
                        Sorting::"Document No.":
                            SetCurrentKey("Document No.");
                        Sorting::"Customer No.":
                            SetCurrentKey("C/V No.");
                        else
                            SetCurrentKey("Real. VAT Entry Date");
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(Totals);
                if SkipPeriod("Period Start", "Period End") then
                    CurrReport.Skip();

                AddSheetCounter += 1;
                StartNewAddSheetSection;
                ExportSalesAddSheetHeader("Period End");
            end;

            trigger OnPreDataItem()
            var
                MinDate: Date;
                MaxDate: Date;
            begin
                AddSheetCounter := 0;

                if not AddSheet or (VATLedgerType = VATLedger.Type::Purchase) then
                    CurrReport.Break();

                if not SetPeriodFilter(SalesAddSheetPeriod) then
                    CurrReport.Break();
            end;
        }
        dataitem(PurchAddSheetPeriod; Date)
        {
            DataItemTableView = SORTING("Period Type", "Period Start");
            dataitem(PurchVATLedgerLineAddSheet; "Integer")
            {
                DataItemTableView = SORTING(Number);

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        GroupBuffer.FindSet
                    else
                        GroupBuffer.Next;

                    LineNo += 1;
                    ExcelReportBuilderManager.AddSection('BODY');

                    ExportPurchVATLedgerLine(GroupBuffer, LineNo);
                end;

                trigger OnPostDataItem()
                begin
                    ExportPurchVATLedgerLineTotals;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, GroupBuffer.Count);
                    LineNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(Totals);
                if not FillGroupBuffer("Period Start", "Period End") then
                    CurrReport.Skip();

                AddSheetCounter += 1;
                StartNewAddSheetSection;
                ExportPurchAddSheetHeader("Period End");
            end;

            trigger OnPreDataItem()
            begin
                AddSheetCounter := 0;
                if not AddSheet or (VATLedgerType = VATLedger.Type::Sales) then
                    CurrReport.Break();

                if not SetPeriodFilter(PurchAddSheetPeriod) then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        ToolTip = 'Specifies how items are sorted on the resulting report.';
                    }
                    field(PeriodType; PeriodType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Type';
                        ToolTip = 'Specifies if the period is Day, Month, or Quarter.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileNameSilent <> '' then
            ExcelReportBuilderManager.ExportDataToClientFile(FileNameSilent)
        else
            ExcelReportBuilderManager.ExportData;
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        TaxRegSetup.Get();

        case VATLedgerType of
            VATLedger.Type::Purchase:
                if AddSheet then begin
                    TaxRegSetup.TestField("Purch. Add. Sheet Templ. Code");
                    ExcelReportBuilderManager.InitTemplate(TaxRegSetup."Purch. Add. Sheet Templ. Code");
                end else begin
                    TaxRegSetup.TestField("Purch. VAT Ledg. Template Code");
                    ExcelReportBuilderManager.InitTemplate(TaxRegSetup."Purch. VAT Ledg. Template Code");
                end;
            VATLedger.Type::Sales:
                if AddSheet then begin
                    TaxRegSetup.TestField("Sales Add. Sheet Templ. Code");
                    ExcelReportBuilderManager.InitTemplate(TaxRegSetup."Sales Add. Sheet Templ. Code");
                end else begin
                    TaxRegSetup.TestField("Sales VAT Ledg. Template Code");
                    ExcelReportBuilderManager.InitTemplate(TaxRegSetup."Sales VAT Ledg. Template Code");
                end;
        end;

        ExcelReportBuilderManager.SetSheet('Sheet01');
        ExcelReportBuilderManager.AddSection('HEADER');
    end;

    var
        CompanyInfo: Record "Company Information";
        TaxRegSetup: Record "Tax Register Setup";
        GroupBuffer: Record "VAT Ledger Line" temporary;
        LocalReportMgt: Codeunit "Local Report Management";
        LocMgt: Codeunit "Localisation Management";
        VATInvJnlMgt: Codeunit "VAT Invoice Journal Management";
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        VATLedgerType: Option;
        Sorting: Option " ","Document Date","Document No.","Customer No.";
        PeriodType: Option Day,Month,Quarter;
        VATLedgerCode: Code[20];
        LineNo: Integer;
        AddSheetCounter: Integer;
        AddSheet: Boolean;
        Text12405: Label 'Quarter';
        Text12406: Label 'From %1 to %2.';
        Totals: array[9, 2] of Decimal;
        FileNameSilent: Text;

    [Scope('OnPrem')]
    procedure InitializeReport(NewVATLedgerType: Option; NewVATLedgerCode: Code[20]; NewAddSheet: Boolean)
    begin
        VATLedgerType := NewVATLedgerType;
        VATLedgerCode := NewVATLedgerCode;
        AddSheet := NewAddSheet;
    end;

    local procedure ExportVATLedgerHeader()
    begin
        if VATLedger.Type = VATLedger.Type::Sales then
            ExportSalesVATLedgerHeader
        else
            ExportPurchVATLedgerHeader;
    end;

    local procedure ExportSalesVATLedgerHeader()
    begin
        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName);
        ExcelReportBuilderManager.AddDataToSection('CompanyVATRegNo',
          CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelReportBuilderManager.AddDataToSection('StartDate', LocMgt.Date2Text(VATLedger."Start Date"));
        ExcelReportBuilderManager.AddDataToSection('EndDate', LocMgt.Date2Text(VATLedger."End Date"));
    end;

    [Scope('OnPrem')]
    procedure ExportPurchVATLedgerHeader()
    begin
        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName);
        ExcelReportBuilderManager.AddDataToSection('CompanyVATRegNo',
          CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelReportBuilderManager.AddDataToSection('StartDate', LocMgt.Date2Text(VATLedger."Start Date"));
        ExcelReportBuilderManager.AddDataToSection('EndDate', LocMgt.Date2Text(VATLedger."End Date"));
    end;

    local procedure ExportSalesVATLedgerLine(VATLedgerLine: Record "VAT Ledger Line")
    var
        PartialText: Text;
    begin
        PartialText := '';
        with VATLedgerLine do begin
            if Partial then
                PartialText := LowerCase(FieldCaption(Partial));
            ExcelReportBuilderManager.AddDataToSection('LineNumber', Format(LineNo));
            ExcelReportBuilderManager.AddDataToSection('OperationTypeCode', "VAT Entry Type");
            ExcelReportBuilderManager.AddDataToSection(
              'DocumentNoAndDate', LocalReportMgt.FormatCompoundExpr("Document No.", Format("Document Date")));
            ExcelReportBuilderManager.AddDataToSection('CDNo', GetCDNoListString);
            ExcelReportBuilderManager.AddDataToSection('TariffNo', "Tariff No.");
            if "Print Revision" then begin
                ExcelReportBuilderManager.AddDataToSection(
                  'RevisionNoAndDate', LocalReportMgt.FormatCompoundExpr("Revision No.", Format("Revision Date")));
                ExcelReportBuilderManager.AddDataToSection(
                  'RevisionOfCorrectionNoAndDate',
                  LocalReportMgt.FormatCompoundExpr("Revision of Corr. No.", Format("Revision of Corr. Date")));
            end;
            ExcelReportBuilderManager.AddDataToSection(
              'CorrectionNoAndDate', LocalReportMgt.FormatCompoundExpr("Correction No.", Format("Correction Date")));
            ExcelReportBuilderManager.AddDataToSection('Name', "C/V Name");
            ExcelReportBuilderManager.AddDataToSection('VATRegNoAndKPP', VATInvJnlMgt.GetCVVATRegKPP("C/V No.", "C/V Type", VATLedgerType));
            if Prepayment or LocalReportMgt.IsVATAgentVendor("C/V No.", "C/V Type") then
                ExcelReportBuilderManager.AddDataToSection(
                  'ExternalDocNoAndDate', LocalReportMgt.FormatCompoundExpr("External Document No.", Format("Payment Date")));
            if LocalReportMgt.IsForeignCurrency("Currency Code") and
               not LocalReportMgt.IsConventionalCurrency("Currency Code") and
               not LocalReportMgt.HasRelationalCurrCode("Currency Code", "Document Date")
            then begin
                ExcelReportBuilderManager.AddDataToSection('CurrencyInfo', GetCurrencyInfo("Currency Code"));
                ExcelReportBuilderManager.AddDataToSection('AmountFCY', FormatValue(Abs(Amount)));
            end;
            ExcelReportBuilderManager.AddDataToSection(
              'AmountLCY', LocalReportMgt.FormatCompoundExpr(FormatValue("Amount Including VAT"), PartialText));
            ExcelReportBuilderManager.AddDataToSection('Base20', FormatBaseValue(Base20, Prepayment));
            ExcelReportBuilderManager.AddDataToSection('Base18', FormatBaseValue(Base18, Prepayment));
            ExcelReportBuilderManager.AddDataToSection('Base10', FormatBaseValue(Base10, Prepayment));
            ExcelReportBuilderManager.AddDataToSection('Amount20', FormatValue(Amount20));
            ExcelReportBuilderManager.AddDataToSection('Amount18', FormatValue(Amount18));
            ExcelReportBuilderManager.AddDataToSection('Amount10', FormatValue(Amount10));
            ExcelReportBuilderManager.AddDataToSection('Base0', FormatBaseValue(Base0, Prepayment));
            ExcelReportBuilderManager.AddDataToSection('BaseVATExempt', FormatValue("Base VAT Exempt"));
        end;
        UpdateTotals(VATLedgerLine);
    end;

    local procedure ExportPurchVATLedgerLine(VATLedgerLine: Record "VAT Ledger Line"; LineNo: Integer)
    begin
        with VATLedgerLine do begin
            ExcelReportBuilderManager.AddDataToSection('LineNumber', Format(LineNo));
            ExcelReportBuilderManager.AddDataToSection('OperationTypeCode', "VAT Entry Type");
            ExcelReportBuilderManager.AddDataToSection(
              'DocumentNoAndDate', LocalReportMgt.FormatCompoundExpr("Document No.", Format("Document Date")));
            if "Print Revision" then begin
                ExcelReportBuilderManager.AddDataToSection(
                  'RevisionNoAndDate', LocalReportMgt.FormatCompoundExpr("Revision No.", Format("Revision Date")));
                ExcelReportBuilderManager.AddDataToSection(
                  'RevisionOfCorrectionNoAndDate',
                  LocalReportMgt.FormatCompoundExpr("Revision of Corr. No.", Format("Revision of Corr. Date")));
            end;
            ExcelReportBuilderManager.AddDataToSection(
              'CorrectionNoAndDate', LocalReportMgt.FormatCompoundExpr("Correction No.", Format("Correction Date")));
            if Prepayment or LocalReportMgt.IsVATAgentVendor("C/V No.", "C/V Type") then
                ExcelReportBuilderManager.AddDataToSection(
                  'ExternalDocNoAndDate', LocalReportMgt.FormatCompoundExpr("External Document No.", Format("Payment Date")))
            else
                if "Full VAT Amount" <> 0 then
                    ExcelReportBuilderManager.AddDataToSection('ExternalDocNoAndDate', GetPurchasePaymentDocNoDate(VATLedgerLine));
            ExcelReportBuilderManager.AddDataToSection(
              'UnrealVATEntryDate', ShowDate(LocalReportMgt.GetVATLedgerItemRealizeDate(VATLedgerLine)));
            ExcelReportBuilderManager.AddDataToSection('Name', "C/V Name");
            ExcelReportBuilderManager.AddDataToSection('VATRegNoAndKPP', VATInvJnlMgt.GetCVVATRegKPP("C/V No.", "C/V Type", VATLedgerType));
            ExcelReportBuilderManager.AddDataToSection('CDNo', GetCDNoListString);

            case true of
                LocalReportMgt.IsForeignCurrency("Currency Code") and
                not LocalReportMgt.IsConventionalCurrency("Currency Code") and
                not LocalReportMgt.HasRelationalCurrCode("Currency Code", "Document Date"):
                    begin
                        ExcelReportBuilderManager.AddDataToSection('CurrencyInfo', GetCurrencyInfo("Currency Code"));
                        ExcelReportBuilderManager.AddDataToSection('DocAmount', FormatValue(Amount));
                    end;
                LocalReportMgt.IsCustomerPrepayment(VATLedgerLine):
                    ExcelReportBuilderManager.AddDataToSection('DocAmount', FormatValue(Amount));
                else
                    ExcelReportBuilderManager.AddDataToSection('DocAmount', FormatValue("Amount Including VAT"));
            end;
            ExcelReportBuilderManager.AddDataToSection('VATAmount', FormatValue(Amount10 + Amount18 + Amount20));
        end;
        UpdateTotals(VATLedgerLine);
    end;

    local procedure ExportSalesVATLedgerLineTotals()
    begin
        ExcelReportBuilderManager.AddSection('FOOTER');
        ExcelReportBuilderManager.AddDataToSection('TotalBase20', FormatTotalValue(Totals[8] [1], Totals[8] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalAmount20', FormatTotalValue(Totals[9] [1], Totals[9] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalBase18', FormatTotalValue(Totals[2] [1], Totals[2] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalAmount18', FormatTotalValue(Totals[3] [1], Totals[3] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalBase10', FormatTotalValue(Totals[4] [1], Totals[4] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalAmount10', FormatTotalValue(Totals[5] [1], Totals[5] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalBase0', FormatTotalValue(Totals[6] [1], Totals[6] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalBaseVATExempt', FormatTotalValue(Totals[7] [1], Totals[7] [2]));
    end;

    local procedure ExportPurchVATLedgerLineTotals()
    begin
        ExcelReportBuilderManager.AddSection('FOOTER');
        ExcelReportBuilderManager.AddDataToSection(
          'TotalVATAmount', FormatTotalValue(
            Totals[3] [1] + Totals[5] [1] + Totals[9] [1], Totals[3] [2] + Totals[5] [2] + Totals[9] [2]));
    end;

    local procedure ExportSalesAddSheetHeader(PeriodEnd: Date)
    begin
        ExcelReportBuilderManager.AddDataToSection('AddSheetCounter', Format(AddSheetCounter));
        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName);
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyVATRegNoAndKPP', CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelReportBuilderManager.AddDataToSection('Period', GetMainPeriodDescription(VATLedger."Start Date", VATLedger."End Date"));
        ExcelReportBuilderManager.AddDataToSection('AddSheetDate', Format(NormalDate(PeriodEnd)));
        ExcelReportBuilderManager.AddDataToSection('DirectorName', CompanyInfo."Director Name");
    end;

    local procedure ExportPurchAddSheetHeader(PeriodEnd: Date)
    begin
        ExcelReportBuilderManager.AddDataToSection('AddSheetCounter', Format(AddSheetCounter));
        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName);
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyVATRegNoAndKPP', CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelReportBuilderManager.AddDataToSection('Period', GetMainPeriodDescription(VATLedger."Start Date", VATLedger."End Date"));
        ExcelReportBuilderManager.AddDataToSection('AddSheetDate', Format(NormalDate(PeriodEnd)));
        ExcelReportBuilderManager.AddDataToSection('DirectorName', CompanyInfo."Director Name");
    end;

    local procedure FormatBaseValue(var VATBase: Decimal; Prepayment: Boolean): Text
    begin
        if VATBase <> 0 then begin
            if Prepayment then begin
                VATBase := 0;
                exit('-');
            end else
                exit(Format(VATBase, 0, '<Precision,2:2><Standard Format,0>'));
        end else
            exit('');
    end;

    local procedure FormatValue(Value: Decimal): Text
    begin
        if Value <> 0 then
            exit(LocalReportMgt.FormatReportValue(Value, 2));
        exit('');
    end;

    local procedure FormatTotalValue(FormatedValue: Decimal; Value: Decimal): Text
    begin
        if Value <> 0 then
            exit(LocalReportMgt.FormatReportValue(FormatedValue, 2));
        exit('');
    end;

    local procedure ShowDate(Date: Date): Text
    begin
        if Date = 0D then
            exit('-');
        exit(Format(Date));
    end;

    local procedure GetCurrencyInfo(CurrencyCode: Code[10]) CurrencyDescription: Text
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        CurrencyDescription := '';
        if CurrencyCode = '' then begin
            GLSetup.Get();
            CurrencyCode := GLSetup."LCY Code";
        end;

        if Currency.Get(CurrencyCode) then begin
            CurrencyDescription :=
              LowerCase(CopyStr(Currency.Description, 1, 1)) + CopyStr(Currency.Description, 2);
            if Currency."RU Bank Digital Code" <> '' then begin
                if CurrencyDescription <> '' then
                    CurrencyDescription := CurrencyDescription + '; ' + Currency."RU Bank Digital Code"
                else
                    CurrencyDescription := Currency."RU Bank Digital Code";
            end;
        end;
    end;

    local procedure SetPeriodFilter(var Period: Record Date): Boolean
    var
        VATLedgerLine: Record "VAT Ledger Line";
        MinDate: Date;
        MaxDate: Date;
    begin
        MinDate := 0D;
        MaxDate := 0D;

        VATLedgerLine.SetCurrentKey("Corr. VAT Entry Posting Date");
        VATLedgerLine.SetRange(Type, VATLedgerType);
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("Additional Sheet", true);
        if VATLedgerLine.FindFirst then
            MinDate := VATLedgerLine."Corr. VAT Entry Posting Date";
        if VATLedgerLine.FindLast then
            MaxDate := VATLedgerLine."Corr. VAT Entry Posting Date";

        if MinDate <> 0D then
            case PeriodType of
                PeriodType::Day:
                    Period.SetRange("Period Type", Period."Period Type"::Date);
                PeriodType::Month:
                    begin
                        Period.SetRange("Period Type", Period."Period Type"::Month);
                        MinDate := CalcDate('<-CM>', MinDate);
                        MaxDate := CalcDate('<CM>', MaxDate);
                    end;
                PeriodType::Quarter:
                    begin
                        Period.SetRange("Period Type", Period."Period Type"::Quarter);
                        MinDate := CalcDate('<-CQ>', MinDate);
                        MaxDate := CalcDate('<CQ>', MaxDate);
                    end;
            end;

        Period.SetRange("Period Start", MinDate, MaxDate);
        exit(not Period.IsEmpty);
    end;

    local procedure SkipPeriod(PeriodStartDate: Date; PeriodEndDate: Date): Boolean
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.SetRange("Additional Sheet", true);
        VATLedgerLine.SetRange("Corr. VAT Entry Posting Date", PeriodStartDate, PeriodEndDate);
        exit(VATLedgerLine.IsEmpty);
    end;

    local procedure FillGroupBuffer(PeriodStartDate: Date; PeriodEndDate: Date): Boolean
    var
        SourceVATEntry: Record "VAT Entry";
        AdjustingVATEntry: Record "VAT Entry";
        AdjustingVATEntryBuffer: Record "VAT Entry" temporary;
        VATLedgerConnection: Record "VAT Ledger Connection";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineBuffer: Record "VAT Ledger Line" temporary;
        AdjustingVATLedgerLine: Record "VAT Ledger Line";
    begin
        with VATLedgerLineBuffer do begin
            VATLedgerLine.SetRange(Type, VATLedger.Type);
            VATLedgerLine.SetRange(Code, VATLedger.Code);
            VATLedgerLine.SetRange("Additional Sheet", true);
            VATLedgerLine.SetRange("Corr. VAT Entry Posting Date", PeriodStartDate, PeriodEndDate);
            if VATLedgerLine.FindSet then
                repeat
                    VATLedgerConnection.Reset();
                    VATLedgerConnection.SetRange("Connection Type", VATLedgerConnection."Connection Type"::Purchase);
                    VATLedgerConnection.SetRange("Purch. Ledger Code", VATLedger.Code);
                    VATLedgerConnection.SetRange("Purch. Ledger Line No.", VATLedgerLine."Line No.");
                    if VATLedgerConnection.FindFirst then begin
                        SourceVATEntry.Get(VATLedgerConnection."VAT Entry No.");
                        TransferFields(VATLedgerLine);

                        if SourceVATEntry."Adjusted VAT Entry No." = 0 then begin
                            AdjustingVATEntry.SetRange("Adjusted VAT Entry No.", SourceVATEntry."Entry No.");
                            AdjustingVATEntry.SetRange("Posting Date", PeriodStartDate, PeriodEndDate);
                            if AdjustingVATEntry.FindFirst then begin
                                VATLedgerConnection.SetRange("Purch. Ledger Line No.");
                                VATLedgerConnection.SetRange("VAT Entry No.", AdjustingVATEntry."Entry No.");
                                if VATLedgerConnection.FindFirst then begin
                                    if AdjustingVATLedgerLine.Get(
                                      VATLedger.Type, VATLedger.Code, VATLedgerConnection."Purch. Ledger Line No.")
                                    then begin
                                        "Amount Including VAT" += AdjustingVATLedgerLine."Amount Including VAT";
                                        Base10 += AdjustingVATLedgerLine.Base10;
                                        Amount10 += AdjustingVATLedgerLine.Amount10;
                                        Base0 += AdjustingVATLedgerLine.Base0;
                                        "Base VAT Exempt" += AdjustingVATLedgerLine."Base VAT Exempt";
                                        "Full VAT Amount" += AdjustingVATLedgerLine."Full VAT Amount";
                                        Base18 += AdjustingVATLedgerLine.Base18;
                                        Amount18 += AdjustingVATLedgerLine.Amount18;
                                        Base20 += AdjustingVATLedgerLine.Base20;
                                        Amount20 += AdjustingVATLedgerLine.Amount20;
                                        AdjustingVATEntryBuffer.TransferFields(AdjustingVATEntry);
                                        AdjustingVATEntryBuffer.Insert();
                                    end;
                                end;
                            end;

                        end;

                        if not AdjustingVATEntryBuffer.Get(SourceVATEntry."Entry No.") then
                            Insert;
                    end;
                until VATLedgerLine.Next = 0;
        end;

        with GroupBuffer do begin
            Reset;
            DeleteAll();

            if VATLedgerLineBuffer.FindSet then
                repeat
                    SetRange("Payment Date", VATLedgerLineBuffer."Payment Date");
                    SetRange("Document No.", VATLedgerLineBuffer."Document No.");
                    SetRange("C/V No.", VATLedgerLineBuffer."C/V No.");
                    SetRange(Correction, VATLedgerLineBuffer.Correction);
                    if not FindFirst then begin
                        TransferFields(VATLedgerLineBuffer);
                        Insert;
                    end else begin
                        "Amount Including VAT" += VATLedgerLineBuffer."Amount Including VAT";
                        Base10 += VATLedgerLineBuffer.Base10;
                        Amount10 += VATLedgerLineBuffer.Amount10;
                        Base0 += VATLedgerLineBuffer.Base0;
                        "Base VAT Exempt" += VATLedgerLineBuffer."Base VAT Exempt";
                        "Full VAT Amount" += VATLedgerLineBuffer."Full VAT Amount";
                        Base18 += VATLedgerLineBuffer.Base18;
                        Amount18 += VATLedgerLineBuffer.Amount18;
                        Base20 += VATLedgerLineBuffer.Base20;
                        Amount20 += VATLedgerLineBuffer.Amount20;
                        Modify;
                    end;
                until VATLedgerLineBuffer.Next = 0;
        end;

        GroupBuffer.Reset();
        exit(not GroupBuffer.IsEmpty);
    end;

    local procedure GetMainPeriodDescription(StartDate: Date; EndDate: Date) MainPeriodDescription: Text
    var
        Period: Record Date;
    begin
        Period.SetRange("Period Type", Period."Period Type"::Month);
        Period.SetRange("Period Start", StartDate, EndDate);
        if Period.Count = 1 then begin
            Period.FindFirst;
            MainPeriodDescription := Period."Period Name" + ' ' + Format(Date2DMY(EndDate, 3));
        end else begin
            Period.SetRange("Period Type", Period."Period Type"::Quarter);
            if Period.Count = 1 then begin
                Period.FindFirst;
                MainPeriodDescription :=
                  Period."Period Name" + ' ' + Text12405 + ' ' + Format(Date2DMY(EndDate, 3));
            end else
                MainPeriodDescription := StrSubstNo(Text12406, StartDate, EndDate);
        end;
    end;

    local procedure UpdateTotals(VATLedgLine: Record "VAT Ledger Line")
    begin
        with VATLedgLine do begin
            Totals[1] [1] += "Amount Including VAT";
            Totals[1] [2] += Abs("Amount Including VAT");
            Totals[2] [1] += Base18;
            Totals[2] [2] += Abs(Base18);
            Totals[3] [1] += Amount18;
            Totals[3] [2] += Abs(Amount18);
            Totals[4] [1] += Base10;
            Totals[4] [2] += Abs(Base10);
            Totals[5] [1] += Amount10;
            Totals[5] [2] += Abs(Amount10);
            Totals[6] [1] += Base0;
            Totals[6] [2] += Abs(Base0);
            Totals[7] [1] += "Base VAT Exempt";
            Totals[7] [2] += Abs("Base VAT Exempt");
            Totals[8] [1] += Base20;
            Totals[8] [2] += Abs(Base20);
            Totals[9] [1] += Amount20;
            Totals[9] [2] += Abs(Amount20);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileNameSilent: Text)
    begin
        FileNameSilent := NewFileNameSilent;
    end;

    local procedure GetPurchasePaymentDocNoDate(VATLedgerLine: Record "VAT Ledger Line"): Text
    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        PaymentDocNoDate: Text;
    begin
        VATLedgerLine.GetPmtVendorDtldLedgerLines(VATLedger."End Date", TempVendorLedgerEntry);
        if TempVendorLedgerEntry.FindSet then
            repeat
                PaymentDocNoDate :=
                  LocalReportMgt.FormatCompoundExpr(
                    PaymentDocNoDate,
                    LocalReportMgt.FormatCompoundExpr(
                      TempVendorLedgerEntry."External Document No.", Format(TempVendorLedgerEntry."Posting Date")));
            until TempVendorLedgerEntry.Next = 0;
        exit(PaymentDocNoDate);
    end;

    local procedure StartNewAddSheetSection()
    begin
        if AddSheetCounter > 1 then begin
            ExcelReportBuilderManager.AddPagebreak;
            ExcelReportBuilderManager.AddSection('HEADER');
        end;
    end;
}

