#if not CLEAN17
page 11774 "Export VAT Statement"
{
    Caption = 'Export VAT Statement (Obsolete)';
    DataCaptionFields = "Statement Template Name", Name;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "VAT Statement Name";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of VAT statement.';
                }
                field(StartDate; StartDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the first date in the period for which VAT statement were exported.';

                    trigger OnValidate()
                    begin
                        StartDateOnAfterValidate;
                    end;
                }
                field(EndDateReq; EndDateReq)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the last date in the period for which VAT statement were exported.';

                    trigger OnValidate()
                    begin
                        EndDateReqOnAfterValidate;
                    end;
                }
                field(Selection; Selection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entries Selection';
                    ToolTip = 'Specifies that VAT entries are included in the VAT Statement Preview window.';
                }
                field(PeriodSelection; PeriodSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Selection';
                    ToolTip = 'Specifies the filtr of VAT entries.';
                }
                field(PrintInIntegers; PrintInIntegers)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Round to Integer';
                    ToolTip = 'Specifies if the vat control report will be rounded to integer';

                    trigger OnValidate()
                    begin
                        PrintInIntegersOnAfterValidate;
                    end;
                }
                group(Control1220025)
                {
                    ShowCaption = false;
                    Visible = RoundingDirectionCtrlVisible;
                    field(RoundingDirection; RoundingDirection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Direction';
                        OptionCaption = 'Nearest,Down,Up';
                        ToolTip = 'Specifies rounding direction';
                    }
                }
                field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies whether to show the reported amounts in the additional reporting currency.';
                }
                field(DeclarationType; DeclarationType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Declaration Type';
                    OptionCaption = 'Recapitulative,Corrective,Supplementary';
                    ToolTip = 'Specifies the declaration type (recapitulative, corrective, supplementary).';

                    trigger OnValidate()
                    begin
                        if DeclarationType <> DeclarationType::Supplementary then
                            ReasonsObservedOn := 0D;
                        DeclarationTypeOnAfterValidate;
                    end;
                }
                field(Month; Month)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Month';
                    ToolTip = 'Specifies the number of monat for VAT statement reporting.';

                    trigger OnValidate()
                    begin
                        if Month <> 0 then
                            if Quarter <> 0 then
                                Error(MonthZeroIfQuarterErr);
                    end;
                }
                field(Quarter; Quarter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quarter';
                    ToolTip = 'Specifies vat control report quarter';

                    trigger OnValidate()
                    begin
                        if Quarter <> 0 then
                            if Month <> 0 then
                                Error(MonthDontEmptyIfQuarErr);
                    end;
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    ToolTip = 'Specifies year of vat control report';
                }
                field(ReasonsObservedOn; ReasonsObservedOn)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reasons Find';
                    Editable = ReasonsObservedOnCtrlEditable;
                    ToolTip = 'Specifies the date of finding reasons of supplementary vat statement';
                }
                field(VATStatDate; VATStatDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement Date';
                    ToolTip = 'Specifies the statement starting date';
                }
                field(FilledByEmployeeNo; FilledByEmployeeNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filled By Employee No.';
                    TableRelation = "Company Officials";
                    ToolTip = 'Specifies the number of employee, who filled VAT statement.';
                }
                field(ZoCode; ZoCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Settlement Next Year Code';
                    OptionCaption = ',Q2,M10,Q,M';
                    ToolTip = 'Specifies vat settlement next year code';
                }
                field(CountryCodeFillFiter; CountryCodeFillFiter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Performance Country';
                    TableRelation = "Country/Region";
                    ToolTip = 'Specifies performance country code for VAT entries filtr.';
                }
                field(SettlementNoFilter; SettlementNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filter VAT Settlement No.';
                    ToolTip = 'Specifies the filter setup of document number which the VAT entries were closed.';
                }
                field(Comments; Comments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Comments';
                    Editable = false;
                    ToolTip = 'Specifies cash document comments.';
                }
                field(Attachments; Attachments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attachments';
                    Editable = false;
                    ToolTip = 'Specifies the number of attachments.';
                }
                field(NoTax; NoTax)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No Tax reliability or Right to deduction';
                    MultiLine = true;
                    ToolTip = 'Specifies if it is no tax reliability or right to deduction.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OK)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'OK';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'This batch job exported VAT statement xml file.';

                trigger OnAction()
                begin
                    FileName := ExportToXML();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        ReasonsObservedOnCtrlEditable := true;
        RoundingDirectionCtrlVisible := true;
    end;

    trigger OnOpenPage()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        CompanyOfficials: Record "Company Officials";
    begin
        FilterGroup(2);
        SetRange("Statement Template Name", "Statement Template Name");
        SetRange(Name, Name);
        FilterGroup(0);
        VATStatementTemplate.Get("Statement Template Name");

        VATStatDate := Today;
        UpdateDateParameters;
        UpdateControls;
        StatReportingSetup.Get();
        if CompanyOfficials.Get(StatReportingSetup."VAT Stat. Filled by Empl. No.") then
            FilledByEmployeeNo := CompanyOfficials."No.";
    end;

    var
        MonthZeroIfQuarterErr: Label 'Month must be 0 if Quarter is filled in.';
        MonthDontEmptyIfQuarErr: Label 'Quarter must be 0 if Month is filled in.';
        MonthOrQuarterErr: Label 'Month or Quarter must be filled in.';
        FileFormatErr: Label 'DPHDP3 file format requires %1 to be added to Supplementary or Supplementary/Corrective VAT Statement.', Comment = '%1==FIELDCAPTION';
        ReasonObserverReqErr: Label 'You must specify Reasons Observed On date in Supplementary or Supplementary/Corrective VAT Statement.';
        VATStatementTemplate: Record "VAT Statement Template";
        FileMgt: Codeunit "File Management";
        VATStatementXML2011: XMLport "VAT Statement 2011";
        FileName: Text;
        DeclarationType: Option Recapitulative,Corrective,Supplementary,"Supplementary/Corrective";
        ReasonsObservedOn: Date;
        VATStatDate: Date;
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        Month: Integer;
        Quarter: Integer;
        Year: Integer;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        RoundingDirection: Option Nearest,Down,Up;
        UseAmtsInAddCurr: Boolean;
        PrintInIntegers: Boolean;
        FilledByEmployeeNo: Code[20];
        NoTax: Boolean;
        ZoCode: Option " ",Q2,M10,Q,M;
        SettlementNoFilter: Text[50];
        CountryCodeFillFiter: Code[10];
        [InDataSet]
        RoundingDirectionCtrlVisible: Boolean;
        [InDataSet]
        ReasonsObservedOnCtrlEditable: Boolean;
        ExportToServerFile: Boolean;

    local procedure UpdateControls()
    begin
        RoundingDirectionCtrlVisible := PrintInIntegers;
        ReasonsObservedOnCtrlEditable := DeclarationIsSupplementary;
    end;

    local procedure UpdateDateParameters()
    var
        DateRec: Record Date;
    begin
        if (StartDate <> 0D) and (EndDateReq <> 0D) then begin
            if EndDateReq < StartDate then
                EndDateReq := StartDate;
            Year := Date2DMY(StartDate, 3);
            Month := Date2DMY(StartDate, 2);
            if (Month = Date2DMY(EndDateReq, 2)) and (Year = Date2DMY(EndDateReq, 3)) then
                Quarter := 0
            else begin
                Month := 0;
                DateRec.SetRange("Period Type", DateRec."Period Type"::Quarter);
                DateRec.SetFilter("Period Start", '..%1', StartDate);
                if DateRec.FindLast then
                    Quarter := DateRec."Period No.";
            end;
        end;
        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;
    end;

    local procedure ExportToXML(): Text
    var
        VATStatementLine: Record "VAT Statement Line";
        TempBlob: Codeunit "Temp Blob";
        OutputStream: OutStream;
    begin
        if (Month = 0) and (Quarter = 0) then
            Error(MonthOrQuarterErr);

        if DeclarationIsSupplementary then begin
            if ReasonsObservedOn = 0D then
                Error(ReasonObserverReqErr);

            if VATStatementTemplate."Allow Comments/Attachments" then begin
                if Comments = 0 then
                    Error(FileFormatErr, FieldCaption(Comments));
                if Attachments = 0 then
                    Error(FileFormatErr, FieldCaption(Attachments));
            end;
        end;

        VATStatementXML2011.ClearVariables();

        VATStatementLine.Reset();
        VATStatementLine.SetRange("Statement Template Name", "Statement Template Name");
        VATStatementLine.SetRange("Statement Name", Name);
        VATStatementLine.SetRange("Date Filter", StartDate, EndDate);
        VATStatementLine.SetRange(Print, true);
        VATStatementLine.SetFilter("Attribute Code", '<>%1', '');
        if VATStatementLine.FindSet then
            repeat
                VATStatementXML2011.AddAmount(GetXMLTag(VATStatementLine), GetColumnValue(VATStatementLine));
            until VATStatementLine.Next() = 0;

        TempBlob.CreateOutStream(OutputStream);
        XMLExportWithParametersTo(OutputStream);
        EncodeAttachmentsToXML(TempBlob);
        exit(FileMgt.BLOBExport(TempBlob, '*.xml', not ExportToServerFile));
    end;

    local procedure XMLExportWithParametersTo(var OutputStream: OutStream)
    var
        Date: Record Date;
        StartDateLoc: Date;
        StopDateLoc: Date;
    begin
        VATStatementXML2011.SetVATStatementName(Rec);
        VATStatementXML2011.SetParameters(
          Month, Quarter, Year, DeclarationType, ReasonsObservedOn, FilledByEmployeeNo, NoTax);

        if Month <> 0 then begin
            Date.SetRange("Period Type", Date."Period Type"::Month);
            Date.SetRange("Period Start", DMY2Date(1, Month, Year));
            Date.SetRange("Period No.", Month);
            if Date.FindLast() then begin
                StartDateLoc := NormalDate(Date."Period Start");
                StopDateLoc := NormalDate(Date."Period End");
            end;
        end else begin
            Date.SetRange("Period Type", Date."Period Type"::Quarter);
            Date.SetRange("Period Start", DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));
            Date.SetRange("Period No.", Quarter);
            if Date.FindLast() then begin
                StartDateLoc := NormalDate(Date."Period Start");
                StopDateLoc := NormalDate(Date."Period End");
            end;
        end;

        if (StartDateLoc <> StartDate) or (StopDateLoc <> EndDateReq) then begin
            StartDateLoc := StartDate;
            StopDateLoc := EndDateReq;
        end else begin
            StartDateLoc := 0D;
            StopDateLoc := 0D;
        end;

        VATStatementXML2011.SetParam2(ZoCode, StartDateLoc, StopDateLoc);
        VATStatementXML2011.SetDestination(OutputStream);
        VATStatementXML2011.Export();
    end;

    local procedure GetColumnValue(var VATStatementLine: Record "VAT Statement Line") ColumnValue: Decimal
    var
        VATAttributeCode: Record "VAT Attribute Code";
        VATStatement: Report "VAT Statement";
    begin
        VATStatement.InitializeRequest(
          Rec, VATStatementLine, Selection,
          PeriodSelection, PrintInIntegers, UseAmtsInAddCurr,
          SettlementNoFilter);

        VATStatement.SetRoundingDirection(RoundingDirection);

        VATStatement.CalcLineTotal(VATStatementLine, ColumnValue, 0);
        if PrintInIntegers then
            ColumnValue := VATStatement.RoundAmount(ColumnValue);

        VATAttributeCode.Get(VATStatementLine."Statement Template Name", VATStatementLine."Attribute Code");
        VATAttributeCode.CheckValue(ColumnValue);
        ColumnValue := Round(ColumnValue, VATAttributeCode.GetRoundingPrecision);

        if VATStatementLine."Print with" = VATStatementLine."Print with"::"Opposite Sign" then
            ColumnValue := -ColumnValue;
    end;

    local procedure DeclarationIsSupplementary(): Boolean
    begin
        exit(DeclarationType in [DeclarationType::Supplementary, DeclarationType::"Supplementary/Corrective"])
    end;

    local procedure GetXMLTag(VATStatementLine: Record "VAT Statement Line"): Code[20]
    var
        VATAttributeCode: Record "VAT Attribute Code";
    begin
        VATAttributeCode.Get(VATStatementLine."Statement Template Name", VATStatementLine."Attribute Code");
        VATAttributeCode.TestField("XML Code");
        exit(VATAttributeCode."XML Code");
    end;

    local procedure EncodeAttachmentsToXML(var TempBlob: Codeunit "Temp Blob")
    begin
        if Attachments > 0 then
            EncodeAttachments(TempBlob);
    end;

    local procedure EncodeAttachments(var TempBlob: Codeunit "Temp Blob")
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocument: DotNet XmlDocument;
        NVInStream: InStream;
        NVOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(NVOutStream);
        XMLDOMManagement.LoadXMLDocumentFromOutStream(NVOutStream, XMLDocument);
        if AreEncodedAttachments(XMLDocument) then begin
            TempBlob.CreateInStream(NVInStream);
            XMLDocument.Save(NVInStream);
        end;
    end;

    local procedure AreEncodedAttachments(var XMLDocument: DotNet XmlDocument) Result: Boolean
    var
        VATStatementAttachment: Record "VAT Statement Attachment";
        TempBlob: Codeunit "Temp Blob";
        XMLRootNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        XMLNodeList: DotNet XmlNodeList;
        IEnumerator: DotNet IEnumerator;
    begin
        VATStatementAttachment.SetRange("VAT Statement Template Name", "Statement Template Name");
        VATStatementAttachment.SetRange("VAT Statement Name", Name);
        XMLRootNode := XMLDocument.DocumentElement;
        if FindNodes(XMLRootNode, 'DPHDP3/Prilohy/ObecnaPriloha', XMLNodeList) then begin
            IEnumerator := XMLNodeList.GetEnumerator;
            while IEnumerator.MoveNext do begin
                XMLNode := IEnumerator.Current;
                VATStatementAttachment.SetRange("File Name", GetAttribute('jm_souboru', XMLNode));

                if VATStatementAttachment.FindFirst then begin
                    VATStatementAttachment.CalcFields(Attachment);
                    if VATStatementAttachment.Attachment.HasValue then begin
                        TempBlob.FromRecord(VATStatementAttachment, VATStatementAttachment.FieldNo(Attachment));
                        if AddEncodedFile(TempBlob, XMLNode) then
                            Result := true;
                    end;
                end;
            end;
        end;
    end;

    local procedure AddEncodedFile(var TempBlob: Codeunit "Temp Blob"; var XMLNode: DotNet XmlNode) Result: Boolean
    var
        XMLDocument: DotNet XmlDocument;
        XMLCDATASection: DotNet XmlCDataSection;
        Data: Text;
    begin
        XMLDocument := XMLNode.OwnerDocument;
        LoadBase64FromFile(TempBlob, Data);
        XMLCDATASection := XMLDocument.CreateCDataSection(Data);
        XMLNode.AppendChild(XMLCDATASection);
        AddCRLF(XMLNode);
        Result := true;
    end;

    local procedure AddCRLF(var XMLNode: DotNet XmlNode)
    var
        XMLText: DotNet XmlText;
        Length: Integer;
        MaxLength: Integer;
        Pos: Integer;
        CRLF: Text[2];
    begin
        MaxLength := 76;
        CRLF[1] := 13;
        CRLF[2] := 10;
        XMLText := XMLNode.FirstChild;
        Length := XMLText.Length;
        while Pos < Length do begin
            XMLText.InsertData(Pos, CRLF);
            Length += 1;
            Pos += MaxLength;
        end;
    end;

    local procedure GetAttribute(AttributeName: Text[250]; var XMLNode: DotNet XmlNode): Text[1024]
    var
        XMLAttributes: DotNet XmlAttributeCollection;
        XMLAttributeNode: DotNet XmlNode;
    begin
        XMLAttributes := XMLNode.Attributes;
        XMLAttributeNode := XMLAttributes.GetNamedItem(AttributeName);
        if IsNull(XMLAttributeNode) then
            exit('');
        exit(Format(XMLAttributeNode.Value));
    end;

    local procedure DeclarationTypeOnAfterValidate()
    begin
        UpdateControls;
    end;

    local procedure PrintInIntegersOnAfterValidate()
    begin
        UpdateControls;
    end;

    local procedure EndDateReqOnAfterValidate()
    begin
        UpdateDateParameters;
    end;

    local procedure StartDateOnAfterValidate()
    begin
        UpdateDateParameters;
    end;

    local procedure FindNodes(XMLRootNode: DotNet XmlNode; NodePath: Text[250]; var ReturnedXMLNodeList: DotNet XmlNodeList): Boolean
    begin
        ReturnedXMLNodeList := XMLRootNode.SelectNodes(NodePath);
        exit(not IsNull(ReturnedXMLNodeList));
    end;

    local procedure LoadBase64FromFile(var TempBlob: Codeunit "Temp Blob"; var Base64String: Text): Boolean
    var
        File: DotNet File;
        Bytes: DotNet Array;
        Convert: DotNet Convert;
        FileName: Text;
    begin
        FileName := FileMgt.ServerTempFileName('');
        FileMgt.BLOBExportToServerFile(TempBlob, FileName);
        Bytes := File.ReadAllBytes(FileName);
        Base64String := Convert.ToBase64String(Bytes);
        exit(true);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure GetFileName(): Text
    begin
        exit(FileName);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;
}
#endif