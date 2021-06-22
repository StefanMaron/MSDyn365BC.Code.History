report 505 "XBRL Export Instance - Spec. 2"
{
    DefaultLayout = RDLC;
    RDLCLayout = './XBRLExportInstanceSpec2.rdlc';
    ApplicationArea = XBRL;
    Caption = 'XBRL Spec. 2 Instance Document';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("XBRL Taxonomy Line"; "XBRL Taxonomy Line")
        {
            DataItemTableView = SORTING("XBRL Taxonomy Name", "Presentation Order") ORDER(Ascending) WHERE("Type Description Element" = CONST(false));
            RequestFilterFields = "Business Unit Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(StartDate; Format(StartDate))
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Description_XBRLTaxonomy; XBRLTaxonomy.Description)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(XBRLTaxonomyName; XBRLTaxonomy.Name)
            {
            }
            column(PeriodLength; PeriodLength)
            {
            }
            column(NoOfPeriods; NoOfPeriods)
            {
            }
            column(LevelLabel; PadStr('', Level * 2) + Label)
            {
            }
            column(SrcType_XBRLTaxonomyLine; "Source Type")
            {
                IncludeCaption = true;
            }
            column(LineDescription; LineDescription)
            {
            }
            column(LineAmount; LineAmount)
            {
                AutoFormatType = 1;
            }
            column(LineNo_XBRLTaxLine; "Line No.")
            {
            }
            column(ShowLine; ShowLine)
            {
            }
            column(ShowLineInBold; ShowLineInBold)
            {
            }
            column(LevelLabelCaption; LevelLabelCaptionLbl)
            {
            }
            column(LineDescriptionCaption; LineDescriptionCaptionLbl)
            {
            }
            column(LineAmountCaption; LineAmountCaptionLbl)
            {
            }
            column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
            {
            }
            column(XBRLDocumentCaption; XBRLDocumentCaptionLbl)
            {
            }
            column(XBRLTaxonomyNameCaption; XBRLTaxonomyNameCaptionLbl)
            {
            }
            column(FilterStringCaption; FilterStringCaptionLbl)
            {
            }
            column(StartDateCaption; StartDateCaptionLbl)
            {
            }
            column(PeriodLengthCaption; PeriodLengthCaptionLbl)
            {
            }
            column(NoOfPeriodsCaption; NoOfPeriodsCaptionLbl)
            {
            }
            dataitem(PeriodNumber; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(TempAmountBufAmount; TempAmountBuf.Amount)
                {
                    AutoFormatType = 1;
                }
                column(PeriodStartAndEndDate; StrSubstNo('%1 - %2', PeriodStartDate, PeriodEndDate))
                {
                }
                column(PeriodNumberNumber; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempAmountBuf.Find('-')
                    else
                        TempAmountBuf.Next;

                    if Number = 1 then
                        PeriodStartDate := StartDate
                    else
                        PeriodStartDate := CalcDate(PeriodLength, PeriodStartDate);
                    PeriodEndDate := CalcDate(PeriodLength, PeriodStartDate) - 1;
                    if ClosingEntryFilter = ClosingEntryFilter::Include then
                        PeriodEndDate := ClosingDate(PeriodEndDate);
                end;

                trigger OnPreDataItem()
                begin
                    if not TempAmountBuf.Find('-') then
                        CurrReport.Break();
                    SetRange(Number, 1, TempAmountBuf.Count);
                end;
            }
            dataitem("XBRL Comment Line"; "XBRL Comment Line")
            {
                DataItemLink = "XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"), "XBRL Taxonomy Line No." = FIELD("Line No.");
                DataItemTableView = SORTING("XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "Comment Type", "Line No.") WHERE("Comment Type" = CONST(Notes));
                column(Comment_XBRLCommentLine; Comment)
                {
                }
                column(LineNo_XBRLCommentLine; "Line No.")
                {
                }

                trigger OnPreDataItem()
                begin
                    SetFilter(Date, '%1..%2|%3', StartDate, EndDate, 0D);
                end;
            }

            trigger OnAfterGetRecord()
            var
                NextXBRLLine: Record "XBRL Taxonomy Line";
                i: Integer;
                HasChildren: Boolean;
            begin
                Progress := Progress + 1;
                if TupleLevel = 0 then begin
                    TupleLevel := 1; // init.
                    TupleNode[1] := RootNode;
                end;
                T1 := Time;
                if T1 > T0 + 250 then begin
                    Window.Update(5, Round(Progress / NoOfRecords * 10000, 1));
                    T0 := Time;
                    T1 := T0;
                end;

                if (NotApplLevel >= 0) and (Level > NotApplLevel) then
                    CurrReport.Skip();
                NotApplLevel := -1;

                if "Source Type" = "Source Type"::"Not Applicable" then begin
                    NotApplLevel := Level;
                    CurrReport.Skip();
                end;

                if XBRLSchema."Line No." <> "XBRL Schema Line No." then
                    XBRLSchema.Get("XBRL Taxonomy Name", "XBRL Schema Line No.");

                NodeName := Name;
                NamespaceName := GetXmlnsStr(XBRLSchema);

                LineAmount := 0;
                CalcFields(Label, Notes, "G/L Map Lines", Rollup);
                if Label = '' then
                    Label := Name;
                LineDescription := XBRLManagement.ExpandString(Description);
                TempAmountBuf.DeleteAll();
                NoOfLineNodes := 0;

                case "Source Type" of
                    "Source Type"::Tuple:
                        begin
                            LineNode[1] := XBRLInstanceDocument.CreateElement(NamespaceName, NodeName, XBRLSchema.targetNamespace);
                            NoOfLineNodes := 1;
                        end;
                    "Source Type"::Notes:
                        ProcessNotes("XBRL Taxonomy Line");
                    "Source Type"::Description:
                        begin
                            LineDescription := XBRLManagement.ExpandString(Description);
                            if LineDescription <> '' then begin
                                LineNode[1] := XBRLInstanceDocument.CreateElement(NamespaceName, NodeName, XBRLSchema.targetNamespace);
                                if "Numeric Context Period Type" = "Numeric Context Period Type"::Instant then
                                    XBRLManagement.AddAttribute(LineNode[1], NonNumericContextAttrName, 'inNC0')
                                else
                                    XBRLManagement.AddAttribute(LineNode[1], NonNumericContextAttrName, 'dnNC0');
                                LineNode[1].InnerText := LineDescription;
                                NoOfLineNodes := 1;
                            end;
                        end;
                    "Source Type"::Constant,
                  "Source Type"::Rollup,
                  "Source Type"::"General Ledger":
                        if Rollup or "G/L Map Lines" or
                           ("Source Type" = "Source Type"::Constant)
                        then begin
                            NoOfLineNodes := NoOfPeriods;
                            for i := 1 to NoOfPeriods do begin
                                if i = 1 then
                                    PeriodStartDate := StartDate
                                else
                                    PeriodStartDate := CalcDate(PeriodLength, PeriodStartDate);
                                PeriodEndDate := CalcDate(PeriodLength, PeriodStartDate) - 1;
                                if ClosingEntryFilter = ClosingEntryFilter::Include then
                                    PeriodEndDate := ClosingDate(PeriodEndDate);
                                XBRLManagement.SetPeriodDates(PeriodStartDate, PeriodEndDate, "XBRL Taxonomy Line");
                                case "Source Type" of
                                    "Source Type"::Constant:
                                        LineAmount := XBRLManagement.CalcConstant("XBRL Taxonomy Line");
                                    "Source Type"::Rollup:
                                        LineAmount := XBRLManagement.CalcRollup("XBRL Taxonomy Line");
                                    "Source Type"::"General Ledger":
                                        LineAmount := XBRLManagement.CalcAmount("XBRL Taxonomy Line");
                                end;
                                LineNode[i] := XBRLInstanceDocument.CreateElement(NamespaceName, NodeName, XBRLSchema.targetNamespace);
                                if "Numeric Context Period Type" = "Numeric Context Period Type"::Instant then
                                    XBRLManagement.AddAttribute(LineNode[i], NumericContextAttrName, StrSubstNo('iNC%1', i))
                                else
                                    XBRLManagement.AddAttribute(LineNode[i], NumericContextAttrName, StrSubstNo('dNC%1', i));
                                if XBRLVersion = 'http://www.xbrl.org/2003/instance' then begin
                                    XBRLManagement.AddAttribute(LineNode[i], 'precision', 'INF');
                                    XBRLManagement.AddAttribute(LineNode[i], 'unitRef', 'currency');
                                end;
                                LineNode[i].InnerText := XBRLManagement.FormatAmount(LineAmount);
                                TempAmountBuf.Init();
                                TempAmountBuf."Entry No." := i;
                                TempAmountBuf.Amount := LineAmount;
                                TempAmountBuf.Insert();
                            end;
                        end;
                end;

                while (TupleLevel > 1) and ("Parent Line No." <> TupleParentLine[TupleLevel]) do begin
                    TupleNode[TupleLevel - 1].AppendChild(TupleNode[TupleLevel]);
                    TupleLevel := TupleLevel - 1;
                end;

                if NoOfLineNodes > 0 then begin
                    if "Source Type" = "Source Type"::Tuple then begin
                        TupleLevel := TupleLevel + 1;
                        TupleParentLine[TupleLevel] := "Line No.";
                        TupleNode[TupleLevel] := LineNode[1];
                    end else
                        for i := 1 to NoOfLineNodes do
                            TupleNode[TupleLevel].AppendChild(LineNode[i]);
                end;

                NextXBRLLine.Copy("XBRL Taxonomy Line");
                if NextXBRLLine.Next = 0 then
                    HasChildren := false
                else
                    HasChildren := (NextXBRLLine.Level = 0) or (NextXBRLLine."Parent Line No." = "Line No.");
                ShowLineInBold := HasChildren or ("Source Type" in ["Source Type"::Rollup, "Source Type"::Tuple]);
                ShowLine :=
                  ShowZeroLines or
                  (("Source Type" = "Source Type"::Notes) and Notes or
                   ("Source Type" = "Source Type"::Tuple) and HasChildren or
                   ("Source Type" = "Source Type"::Description) and ((LineDescription <> '') or HasChildren));
            end;

            trigger OnPostDataItem()
            var
                TempFile: File;
                ToFile: Text[1024];
                FullPathNameOfExportFile: Text[1024];
            begin
                while TupleLevel > 1 do begin
                    TupleNode[TupleLevel - 1].AppendChild(TupleNode[TupleLevel]);
                    TupleLevel := TupleLevel - 1;
                end;

                Window.Close;

                if CreateFile then begin
                    TempFile.CreateTempFile;
                    FullPathNameOfExportFile := TempFile.Name;
                    TempFile.Close;
                    XBRLInstanceDocument.Save(FullPathNameOfExportFile);
                    ToFile := Text025;
                    Download(FullPathNameOfExportFile, Text024, '', Text001, ToFile);
                    Message(Text017, ToFile);
                end;
            end;

            trigger OnPreDataItem()
            var
                ProcessingInstruction: DotNet XmlProcessingInstruction;
                schemaLocationStr: Text[1024];
                xmlnsStr: Text[1024];
                i: Integer;
            begin
                Window.Open(Text009);

                with XBRLSchema do begin
                    SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
                    if Find('-') then
                        if "xmlns:xbrli" in ['http://www.xbrl.org/2001/instance', 'http://www.xbrl.org/2003/instance'] then
                            XBRLVersion := "xmlns:xbrli"
                        else
                            Error(Text023, "xmlns:xbrli");
                end;

                XBRLManagement.InitializeOptions(NoOfPeriods, 0);
                NoOfRecords := 0;
                Progress := 0;
                XBRLInstanceDocument := XBRLInstanceDocument.XmlDocument;
                ProcessingInstruction := XBRLInstanceDocument.CreateProcessingInstruction('xml', 'version="1.0" encoding="UTF-8"');
                XBRLInstanceDocument.AppendChild(ProcessingInstruction);
                case XBRLVersion of
                    'http://www.xbrl.org/2001/instance':
                        begin
                            xbrliPrefix := 'xbrli:';
                            RootNode := XBRLInstanceDocument.CreateElement(StrSubstNo('%1group', xbrliPrefix));
                            if XBRLTaxonomy.targetNamespace <> '' then
                                XBRLManagement.AddAttribute(RootNode, 'xmlns', XBRLTaxonomy.targetNamespace);
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:xbrli', XBRLVersion);
                            NonNumericContextElemName := 'nonNumericContext';
                            NumericContextElemName := 'numericContext';
                            NonNumericContextAttrName := 'nonNumericContext';
                            NumericContextAttrName := 'numericContext';
                        end;
                    'http://www.xbrl.org/2003/instance':
                        begin
                            xbrliPrefix := '';
                            RootNode := XBRLInstanceDocument.CreateElement('xbrl');
                            XBRLManagement.AddAttribute(RootNode, 'xmlns', XBRLVersion);
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:link', 'http://www.xbrl.org/2003/linkbase');
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:xlink', 'http://www.w3.org/1999/xlink');
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:iso4217', 'http://www.xbrl.org/2003/iso4217');
                            NonNumericContextElemName := 'context';
                            NumericContextElemName := 'context';
                            NonNumericContextAttrName := 'contextRef';
                            NumericContextAttrName := 'contextRef';
                        end;
                end;

                with XBRLSchema do begin
                    SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
                    if Find('-') then
                        repeat
                            xmlnsStr := GetXmlnsStr(XBRLSchema);
                            XBRLManagement.AddAttribute(
                              RootNode, StrSubstNo('xmlns:%1', xmlnsStr), targetNamespace);
                            if (schemaLocation <> '') and (targetNamespace <> '') then
                                if schemaLocationStr = '' then
                                    schemaLocationStr :=
                                      StrSubstNo('%1 %2', targetNamespace, schemaLocation)
                                else
                                    schemaLocationStr :=
                                      schemaLocationStr + ' ' +
                                      StrSubstNo('%1 %2', targetNamespace, schemaLocation);
                        until Next = 0;
                end;
                if (XBRLTaxonomy.targetNamespace <> '') and (XBRLTaxonomy.schemaLocation <> '') then
                    schemaLocationStr := StrSubstNo('%1 %2', XBRLTaxonomy.targetNamespace, XBRLTaxonomy.schemaLocation);

                if XBRLVersion = 'http://www.xbrl.org/2001/instance' then begin
                    XBRLManagement.AddAttribute(RootNode, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
                    XBRLManagement.AddAttribute(RootNode, 'xsi:schemaLocation', schemaLocationStr);
                end;

                XBRLInstanceDocument.AppendChild(RootNode);

                if XBRLVersion = 'http://www.xbrl.org/2003/instance' then begin
                    XBRLTaxonomy.TestField(schemaLocation);
                    LineNode[1] := XBRLInstanceDocument.CreateElement('link', 'schemaRef', 'http://www.xbrl.org/2003/linkbase');
                    XBRLManagement.AddAttributeWithNamespace(LineNode[1], 'type', 'simple', 'xlink', 'http://www.w3.org/1999/xlink');
                    XBRLManagement.AddAttributeWithNamespace(
                      LineNode[1], 'arcrole', 'http://www.w3.org/1999/xlink/properties/linkbase', 'xlink', 'http://www.w3.org/1999/xlink');
                    XBRLManagement.AddAttributeWithNamespace(
                      LineNode[1], 'href', XBRLTaxonomy.schemaLocation, 'xlink', 'http://www.w3.org/1999/xlink');
                    RootNode.AppendChild(LineNode[1]);
                end;

                EndDate := StartDate;
                for i := 1 to NoOfPeriods do
                    EndDate := CalcDate(PeriodLength, EndDate);
                EndDate := EndDate - 1;

                for i := 0 to NoOfPeriods do begin
                    if i = 0 then begin
                        PeriodStartDate := StartDate;
                        PeriodEndDate := EndDate;
                    end else begin
                        if i = 1 then
                            PeriodStartDate := StartDate
                        else
                            PeriodStartDate := CalcDate(PeriodLength, PeriodStartDate);
                        PeriodEndDate := CalcDate(PeriodLength, PeriodStartDate) - 1;
                    end;

                    if xbrliPrefix = '' then
                        xbrliNamespace := ''
                    else
                        xbrliNamespace := XBRLVersion;

                    if i = 0 then begin
                        DurationContextNode :=
                          XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NonNumericContextElemName), xbrliNamespace);
                        XBRLManagement.AddAttribute(DurationContextNode, 'id', 'dnNC0');
                        InstantContextNode :=
                          XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NonNumericContextElemName), xbrliNamespace);
                        XBRLManagement.AddAttribute(InstantContextNode, 'id', 'inNC0');
                    end else begin
                        DurationContextNode :=
                          XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NumericContextElemName), xbrliNamespace);
                        XBRLManagement.AddAttribute(DurationContextNode, 'id', StrSubstNo('dNC%1', i));
                        if XBRLVersion = 'http://www.xbrl.org/2001/instance' then begin
                            XBRLManagement.AddAttribute(DurationContextNode, 'precision', '18');
                            if cwa then
                                XBRLManagement.AddAttribute(DurationContextNode, 'cwa', 'true')
                            else
                                XBRLManagement.AddAttribute(DurationContextNode, 'cwa', 'false');
                        end;
                        InstantContextNode :=
                          XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NumericContextElemName), xbrliNamespace);
                        XBRLManagement.AddAttribute(InstantContextNode, 'id', StrSubstNo('iNC%1', i));
                        if XBRLVersion = 'http://www.xbrl.org/2001/instance' then begin
                            XBRLManagement.AddAttribute(InstantContextNode, 'precision', '18');
                            if cwa then
                                XBRLManagement.AddAttribute(InstantContextNode, 'cwa', 'true')
                            else
                                XBRLManagement.AddAttribute(InstantContextNode, 'cwa', 'false');
                        end;
                    end;
                    ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix), xbrliNamespace);
                    ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix), xbrliNamespace);

                    XBRLManagement.AddAttribute(ContextNode3, 'scheme', SchemeName);
                    ContextNode3.InnerText := SchemeIdentifier;
                    ContextNode2.AppendChild(ContextNode3);
                    ContextNode3 := ContextNode2.CloneNode(true);
                    InstantContextNode.AppendChild(ContextNode2);
                    DurationContextNode.AppendChild(ContextNode3);

                    ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix), xbrliNamespace);
                    ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1startDate', xbrliPrefix), xbrliNamespace);
                    ContextNode3.InnerText :=
                      StrSubstNo('%1-%2-%3',
                        Date2DMY(PeriodStartDate, 3),
                        CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                        CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                    ContextNode2.AppendChild(ContextNode3);
                    ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1endDate', xbrliPrefix), xbrliNamespace);
                    ContextNode3.InnerText :=
                      StrSubstNo('%1-%2-%3',
                        Date2DMY(PeriodEndDate, 3),
                        CopyStr(Format(100 + Date2DMY(PeriodEndDate, 2)), 2),
                        CopyStr(Format(100 + Date2DMY(PeriodEndDate, 1)), 2));
                    ContextNode2.AppendChild(ContextNode3);
                    DurationContextNode.AppendChild(ContextNode2);

                    ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix), xbrliNamespace);
                    ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1instant', xbrliPrefix), xbrliNamespace);
                    ContextNode3.InnerText :=
                      StrSubstNo('%1-%2-%3',
                        Date2DMY(PeriodEndDate, 3),
                        CopyStr(Format(100 + Date2DMY(PeriodEndDate, 2)), 2),
                        CopyStr(Format(100 + Date2DMY(PeriodEndDate, 1)), 2));
                    ContextNode2.AppendChild(ContextNode3);
                    InstantContextNode.AppendChild(ContextNode2);

                    if (XBRLVersion = 'http://www.xbrl.org/2001/instance') and (i >= 0) then begin
                        ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1unit', xbrliPrefix), xbrliNamespace);
                        ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1measure', xbrliPrefix), xbrliNamespace);
                        ContextNode3.InnerText := StrSubstNo('iso4217:%1', CurrencyCode);
                        ContextNode2.AppendChild(ContextNode3);
                        ContextNode3 := ContextNode2.CloneNode(true);
                        DurationContextNode.AppendChild(ContextNode2);
                        InstantContextNode.AppendChild(ContextNode3);
                    end;
                    RootNode.AppendChild(DurationContextNode);
                    RootNode.AppendChild(InstantContextNode);
                end;
                if XBRLVersion = 'http://www.xbrl.org/2003/instance' then begin
                    ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1unit', xbrliPrefix), xbrliNamespace);
                    XBRLManagement.AddAttribute(ContextNode2, 'id', 'currency');
                    ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1measure', xbrliPrefix), xbrliNamespace);
                    ContextNode3.InnerText := StrSubstNo('iso4217:%1', CurrencyCode);
                    ContextNode2.AppendChild(ContextNode3);
                    RootNode.AppendChild(ContextNode2);
                end;

                SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
                SetRange("Label Language Filter", LabelLanguage);
                if NoOfRecords = 0 then
                    NoOfRecords := Count;
                if NoOfRecords = 0 then
                    Error(Text018);
                Progress := 0;
                NotApplLevel := -1;
                T0 := Time;
                T1 := T0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(XBRLTaxonomyName; XBRLTaxonomyName)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'XBRL Taxonomy Name';
                        TableRelation = "XBRL Taxonomy";
                        ToolTip = 'Specifies the taxonomy from which you want to export data into the instance document.';

                        trigger OnValidate()
                        begin
                            if XBRLTaxonomyName <> '' then
                                XBRLTaxonomy.Get(XBRLTaxonomyName);
                        end;
                    }
                    field(LabelLanguage; LabelLanguage)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Label Language';
                        ToolTip = 'Specifies the language you want the labels to be shown in. The label is a user-readable element of the taxonomy.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
                            XBRLTaxonomyLabels: Page "XBRL Taxonomy Labels";
                        begin
                            XBRLTaxonomyLabel.SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
                            if not XBRLTaxonomyLabel.FindFirst then
                                Error(Text022, XBRLTaxonomyName);
                            XBRLTaxonomyLabel.SetRange(
                              "XBRL Taxonomy Line No.", XBRLTaxonomyLabel."XBRL Taxonomy Line No.");
                            XBRLTaxonomyLabels.SetTableView(XBRLTaxonomyLabel);
                            XBRLTaxonomyLabels.LookupMode := true;
                            if XBRLTaxonomyLabels.RunModal = ACTION::LookupOK then begin
                                XBRLTaxonomyLabels.GetRecord(XBRLTaxonomyLabel);
                                Text := XBRLTaxonomyLabel."XML Language Identifier";
                                exit(true);
                            end;
                            exit(false);
                        end;

                        trigger OnValidate()
                        var
                            XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
                        begin
                            if LabelLanguage <> '' then begin
                                XBRLTaxonomyLabel.SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
                                XBRLTaxonomyLabel.SetRange("XML Language Identifier", LabelLanguage);
                                if XBRLTaxonomyLabel.IsEmpty then
                                    Error(UnknownXMLLanguageIDErr, LabelLanguage);
                            end;
                        end;
                    }
                    field(CreateFile; CreateFile)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Create File';
                        ToolTip = 'Specifies if you want to create a file that contains the instance document.';
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date to be included in the instance document.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies the number of periods you want to include in the instance document.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the length of the period by using date formulas.';
                    }
                    field(ClosingEntryFilter; ClosingEntryFilter)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Closing Entries';
                        OptionCaption = 'Include,Exclude';
                        ToolTip = 'Specifies if you want to include closing entries in the instance document.';
                    }
                    field(cwa; cwa)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Document Complete';
                        ToolTip = 'Specifies if the instance document contains all the information that is required to perform additional analysis.';
                    }
                    field(CurrencyCode; CurrencyCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ISO Currency Code';
                        ToolTip = 'Specifies the three-letter currency code for this instance document. The currency code should comply with the ISO 4217 standards. The currency code you enter should be the code for the local currency of the company whose data that you are exporting, not the additional reporting currency.';
                    }
                    field(SchemeName; SchemeName)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Scheme';
                        ToolTip = 'Specifies the scheme for the XBRL instance document.';
                    }
                    field(SchemeIdentifier; SchemeIdentifier)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Scheme Identifier';
                        ToolTip = 'Specifies the scheme identifier to define the entity within the context section of the XBRL instance document.';
                    }
                    field(ShowZeroLines; ShowZeroLines)
                    {
                        ApplicationArea = XBRL;
                        Caption = 'Show Zero Lines';
                        ToolTip = 'Specifies if you want to include all lines in the instance document, even those lines that contain a zero. Clear if you want all zero lines to be skipped. Note that any non-numeric data is not affected by this selection.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if SchemeName = '' then
                SchemeName := CompanyInfo."Home Page";
            if SchemeIdentifier = '' then
                SchemeIdentifier := CompanyInfo."VAT Registration No.";
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();

        if CurrencyCode = '' then
            CurrencyCode := GLSetup."LCY Code";
        if NoOfPeriods = 0 then
            NoOfPeriods := 1;
    end;

    trigger OnPreReport()
    begin
        if XBRLTaxonomyName = '' then
            Error(Text003);
        if StartDate = 0D then
            Error(Text004);
        if NoOfPeriods <= 0 then
            Error(Text007);
        if SchemeIdentifier = '' then
            Error(Text010);

        XBRLTaxonomy.Get(XBRLTaxonomyName);

        FilterString := "XBRL Taxonomy Line".GetFilters;

        "XBRL Taxonomy Line".SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
        "XBRL Taxonomy Line".SetFilter(
          "Source Type", '<>%1', "XBRL Taxonomy Line"."Source Type"::"Not Applicable");
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        XBRLTaxonomy: Record "XBRL Taxonomy";
        XBRLSchema: Record "XBRL Schema";
        TempAmountBuf: Record "Entry No. Amount Buffer" temporary;
        XBRLManagement: Codeunit "XBRL Management";
        XBRLInstanceDocument: DotNet XmlDocument;
        RootNode: DotNet XmlNode;
        InstantContextNode: DotNet XmlNode;
        DurationContextNode: DotNet XmlNode;
        ContextNode2: DotNet XmlNode;
        ContextNode3: DotNet XmlNode;
        LineNode: array[50] of DotNet XmlNode;
        NoteNode: DotNet XmlNode;
        TupleNode: array[50] of DotNet XmlNode;
        Window: Dialog;
        NoOfLineNodes: Integer;
        XBRLTaxonomyName: Code[20];
        LabelLanguage: Text[30];
        ShowZeroLines: Boolean;
        StartDate: Date;
        EndDate: Date;
        PeriodLength: DateFormula;
        ClosingEntryFilter: Option Include,Exclude;
        cwa: Boolean;
        SchemeName: Text[250];
        SchemeIdentifier: Text[250];
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        NoOfPeriods: Integer;
        NoOfRecords: Integer;
        Progress: Integer;
        CurrencyCode: Code[10];
        Text001: Label 'XBRL Instance Document Files|*.xml|All Files|*.*';
        Text003: Label 'You must select an XBRL Taxonomy.';
        Text004: Label 'You must enter a period ending date.';
        Text007: Label 'You must enter a positive number of periods.';
        Text009: Label 'Exporting XBRL Lines       @5@@@@@@@@@@';
        Text010: Label 'You must define a scheme identifier.';
        Text017: Label 'The XBRL File: %1, has been successfully created.';
        Text018: Label 'There are no XBRL lines to export.';
        CreateFile: Boolean;
        LineAmount: Decimal;
        LineDescription: Text[250];
        FilterString: Text;
        NamespaceName: Text[250];
        Text022: Label 'There are no labels defined for %1.';
        NodeName: Text[250];
        TupleLevel: Integer;
        TupleParentLine: array[50] of Integer;
        ShowLine: Boolean;
        ShowLineInBold: Boolean;
        NotApplLevel: Integer;
        T0: Time;
        T1: Time;
        XBRLVersion: Text[250];
        Text023: Label 'Unknown XBRL version: %1.';
        xbrliPrefix: Text[6];
        xbrliNamespace: Text[250];
        NumericContextAttrName: Text[30];
        NonNumericContextAttrName: Text[30];
        Text024: Label 'Export';
        Text025: Label 'Default.xml';
        NumericContextElemName: Text[30];
        NonNumericContextElemName: Text[30];
        LevelLabelCaptionLbl: Label 'Label';
        LineDescriptionCaptionLbl: Label 'Description';
        LineAmountCaptionLbl: Label 'Amount';
        CurrReportPAGENOCaptionLbl: Label 'Page';
        XBRLDocumentCaptionLbl: Label 'XBRL Document';
        XBRLTaxonomyNameCaptionLbl: Label 'XBRL Taxonomy Name';
        FilterStringCaptionLbl: Label 'Filters';
        StartDateCaptionLbl: Label 'Starting Date';
        PeriodLengthCaptionLbl: Label 'Period Length';
        NoOfPeriodsCaptionLbl: Label 'Number of Periods';
        UnknownXMLLanguageIDErr: Label 'Unknown XML language ID: %1.', Comment = '%1: Text Language ID';

    local procedure ProcessNotes(XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    var
        XBRLCommentLine: Record "XBRL Comment Line";
        BufTxt: array[3] of Text[1024];
        i: Integer;
        More: Boolean;
    begin
        // Only allows up to 2048 chars...
        with XBRLCommentLine do begin
            SetRange("XBRL Taxonomy Name", XBRLTaxonomyLine."XBRL Taxonomy Name");
            SetRange("XBRL Taxonomy Line No.", XBRLTaxonomyLine."Line No.");
            SetRange("Comment Type", "Comment Type"::Notes);
            SetFilter(Date, '%1..%2|%3', StartDate, EndDate, 0D);
            if Find('-') then begin
                More := true;
                i := 1;
                while More and (i <= 2) do begin
                    if MaxStrLen(BufTxt[i]) < StrLen(BufTxt[i]) + StrLen(Comment) then begin
                        i := i + 1;
                        BufTxt[i] := ' ';
                    end;
                    if BufTxt[i] = '' then
                        BufTxt[i] := Comment
                    else
                        BufTxt[i] := BufTxt[i] + ' ' + Comment;
                    More := Next <> 0;
                end;
                NoteNode := XBRLInstanceDocument.CreateElement(NamespaceName, NodeName, XBRLSchema.targetNamespace);
                NoteNode.InnerText := BufTxt[1] + BufTxt[2];
                if XBRLTaxonomyLine."Numeric Context Period Type" = XBRLTaxonomyLine."Numeric Context Period Type"::Instant then
                    XBRLManagement.AddAttribute(NoteNode, NonNumericContextAttrName, 'inNC0')
                else
                    XBRLManagement.AddAttribute(NoteNode, NonNumericContextAttrName, 'dnNC0');
                RootNode.AppendChild(NoteNode);
                Clear(NoteNode);
            end;
        end;
    end;

    local procedure GetXmlnsStr(var XBRLSchema2: Record "XBRL Schema"): Text[30]
    begin
        if XBRLSchema2.Description = '' then
            exit(
              StrSubstNo(
                '%1%2', ConvertStr(XBRLSchema2."XBRL Taxonomy Name", ' ', '_'),
                XBRLSchema."Line No."));
        exit(ConvertStr(XBRLSchema2.Description, ' :=<>', '_____'));
    end;
}

