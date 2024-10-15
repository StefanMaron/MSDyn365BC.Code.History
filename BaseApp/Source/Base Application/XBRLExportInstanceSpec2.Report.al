#if not CLEAN20
report 505 "XBRL Export Instance - Spec. 2"
{
    DefaultLayout = RDLC;
    RDLCLayout = './XBRLExportInstanceSpec2.rdlc';
    ApplicationArea = XBRL;
    Caption = 'XBRL Specification 2 Instance Document';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteReason = 'XBRL feature will be discontinued';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

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
            column(XBRLTaxonomyDesc; XBRLTaxonomy.Description)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
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
            column(Level2Label; PadStr('', Level * 2) + Label)
            {
            }
            column(SourceType_XBRLTaxonomyLine; "Source Type")
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
            column(LineNo_XBRLTaxonomyLine; "XBRL Taxonomy Line"."Line No.")
            {
            }
            column(ShowLine; ShowLine)
            {
            }
            column(ShowLineInBold; ShowLineInBold)
            {
            }
            column(LabelCaption; LabelCaptionLbl)
            {
            }
            column(LineDescriptionCaption; LineDescriptionCaptionLbl)
            {
            }
            column(LineAmountCaption; LineAmountCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
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
                column(TempAmtBufAmt; TempAmountBuf.Amount)
                {
                    AutoFormatType = 1;
                }
                column(levelTaxonomyLineLabel; PadStr('', "XBRL Taxonomy Line".Level * 2) + "XBRL Taxonomy Line".Label)
                {
                }
                column(PeriodStartDatePeriodEndDate; StrSubstNo('%1 - %2', PeriodStartDate, PeriodEndDate))
                {
                }
                column(Number_PeriodNumber; PeriodNumber.Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempAmountBuf.Find('-')
                    else
                        TempAmountBuf.Next();

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
                    PeriodNumber.SetRange(Number, 1, TempAmountBuf.Count);
                end;
            }
            dataitem("XBRL Comment Line"; "XBRL Comment Line")
            {
                DataItemLink = "XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"), "XBRL Taxonomy Line No." = FIELD("Line No.");
                DataItemTableView = SORTING("XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "Comment Type", "Line No.") WHERE("Comment Type" = CONST(Notes));
                column(XBRLTaxonomyLineNo_XBRLCommentLine; "XBRL Taxonomy Line No.")
                {
                }
                column(LineNo_XBRLCommentLine; "Line No.")
                {
                }
                column(Comment_XBRLCommentLine; Comment)
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
                    Window.Update(5, Round((Progress / NoOfRecords * 10000), 1));
                    T0 := Time;
                    T1 := T0;
                end;

                if (NotApplLevel >= 0) and (Level > NotApplLevel) then
                    CurrReport.Skip();
                NotApplLevel := -1;

                if ("Source Type" = "Source Type"::"Not Applicable") then begin
                    NotApplLevel := Level;
                    CurrReport.Skip();
                end;

                // IF XBRLSchema."Line No." <> "XBRL Schema Line No." THEN
                // XBRLSchema.GET("XBRL Taxonomy Name","XBRL Schema Line No.");

                // NodeName := Name;
                NodeName := "XBRL Taxonomy Line".Name;
                // NamespaceName := GetXmlnsStr(XBRLSchema);
                NamespaceName := 'acra';

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
                        begin
                            ProcessNotes("XBRL Taxonomy Line");
                        end;
                    "Source Type"::Description:
                        begin
                            LineDescription := XBRLManagement.ExpandString(Description);
                            if LineDescription <> '' then begin
                                LineNode[1] := XBRLInstanceDocument.CreateElement(NamespaceName, NodeName, XBRLSchema.targetNamespace);
                                // IF "Numeric Context Period Type" = "Numeric Context Period Type"::Instant THEN
                                // XBRLManagement.AddAttribute(LineNode[1],NonNumericContextAttrName,'inNC0')
                                // ELSE
                                // XBRLManagement.AddAttribute(LineNode[1],NonNumericContextAttrName,'dnNC0');
                                XBRLManagement.AddAttribute(LineNode[1], NonNumericContextAttrName, 'Company_Current_AsOf');
                                LineNode[1].InnerText := LineDescription;
                                NoOfLineNodes := 1;
                            end;
                        end;
                    "Source Type"::Constant,
                    "XBRL Taxonomy Line"."Source Type"::Rollup,
                    "XBRL Taxonomy Line"."Source Type"::"General Ledger":
                        begin
                            if "XBRL Taxonomy Line".Rollup or "XBRL Taxonomy Line"."G/L Map Lines" or
                               ("XBRL Taxonomy Line"."Source Type" = "XBRL Taxonomy Line"."Source Type"::Constant)
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
                                        "XBRL Taxonomy Line"."Source Type"::Rollup:
                                            LineAmount := XBRLManagement.CalcRollup("XBRL Taxonomy Line");
                                        "XBRL Taxonomy Line"."Source Type"::"General Ledger":
                                            LineAmount := XBRLManagement.CalcAmount("XBRL Taxonomy Line");
                                    end;
                                    LineNode[i] := XBRLInstanceDocument.CreateElement(NamespaceName, NodeName, XBRLSchema.targetNamespace);
                                    if "Numeric Context Period Type" = "Numeric Context Period Type"::Instant then
                                        XBRLManagement.AddAttribute(LineNode[i], NumericContextAttrName, StrSubstNo('iNC%1', i))
                                    else
                                        XBRLManagement.AddAttribute(LineNode[i], NumericContextAttrName, StrSubstNo('dNC%1', i));
                                    if XBRLVersion = 'http://www.xbrl.org/2003/instance' then begin
                                        // XBRLManagement.AddAttribute(LineNode[i],'precision','INF');
                                        // XBRLManagement.AddAttribute(LineNode[i],'unitRef','currency');
                                        XBRLManagement.AddAttribute(LineNode[i], NonNumericContextElemName, 'Company_Current_ForPeriod');
                                        XBRLManagement.AddAttribute(LineNode[i], 'decimals', Format(CurrencyUnit));
                                        XBRLManagement.AddAttribute(LineNode[i], 'unitRef', 'monetary_unit');
                                    end;
                                    LineNode[i].InnerText := XBRLManagement.FormatAmount(LineAmount);
                                    TempAmountBuf.Init();
                                    TempAmountBuf."Entry No." := i;
                                    TempAmountBuf.Amount := LineAmount;
                                    TempAmountBuf.Insert();
                                    LineNodes[i] := LineNode[i];
                                end;
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
                        if (("XBRL Taxonomy Line"."Source Type" = "XBRL Taxonomy Line"."Source Type"::Rollup) and
                            ("XBRL Taxonomy Line".Rollup)) or
                            (("XBRL Taxonomy Line"."Source Type" = "XBRL Taxonomy Line"."Source Type"::"General Ledger") and
                            ("XBRL Taxonomy Line"."G/L Map Lines"))
                        then
                            for i := 1 to NoOfPeriods do
                                TupleNode[TupleLevel].AppendChild(LineNodes[i])
                        else
                            for i := 1 to NoOfLineNodes do
                                TupleNode[TupleLevel].AppendChild(LineNode[i]);
                end;

                NextXBRLLine.Copy("XBRL Taxonomy Line");
                if NextXBRLLine.Next() = 0 then
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
            begin
                while TupleLevel > 1 do begin
                    TupleNode[TupleLevel - 1].AppendChild(TupleNode[TupleLevel]);
                    TupleLevel := TupleLevel - 1;
                end;

                Window.Close();
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
                XBRLInstanceDocument := XBRLInstanceDocument.XmlDocument();
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
                            XBRLManagement.AddAttribute(RootNode, 'xmlns1', XBRLVersion);
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:acra', 'http://www.acra.gov.sg/acra');
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:iso4217', 'http://www.xbrl.org/2003/iso4217');

                            XBRLManagement.AddAttribute(RootNode, 'xmlns:link', 'http://www.xbrl.org/2003/linkbase');
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:xlink', 'http://www.w3.org/1999/xlink');
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:iso4217', 'http://www.xbrl.org/2003/iso4217');
                            XBRLManagement.AddAttribute(RootNode, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
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
                            xmlnsStr := 'acra';
                            XBRLManagement.AddAttribute(
                              RootNode, StrSubstNo('xmlns:%1', xmlnsStr), XBRLSchema.targetNamespace);
                            if (XBRLSchema.schemaLocation <> '') and (XBRLSchema.targetNamespace <> '') then
                                if schemaLocationStr = '' then
                                    schemaLocationStr :=
                                      StrSubstNo('%1 %2', XBRLSchema.targetNamespace, XBRLSchema.schemaLocation)
                                else
                                    schemaLocationStr :=
                                      schemaLocationStr + ' ' +
                                      StrSubstNo('%1 %2', XBRLSchema.targetNamespace, XBRLSchema.schemaLocation);
                        until Next() = 0;
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
                    XBRLManagement.AddAttributeWithNamespace(LineNode[1], 'arcrole', 'http://www.w3.org/1999/xlink/properties/linkbase', 'xlink', 'http://www.w3.org/1999/xlink');
                    XBRLManagement.AddAttributeWithNamespace(LineNode[1], 'href', 'https://www.fsm.acra.gov.sg/acra-xbrl/v1/acra-taxonomy-2007-v1.20.xsd', 'xlink', 'http://www.w3.org/1999/xlink');
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
                        DurationContextNode := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NonNumericContextElemName), xbrliNamespace);
                        // XBRLManagement.AddAttribute(DurationContextNode,'id','dnNC0');

                        XBRLManagement.AddAttribute(DurationContextNode, 'id', 'Company_Current_ForPeriod');
                        ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix));
                        ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix));
                        XBRLManagement.AddAttribute(ContextNode3, 'scheme', SchemeName);
                        ContextNode3.InnerText := SchemeIdentifier;
                        ContextNode2.AppendChild(ContextNode3);
                        DurationContextNode.AppendChild(ContextNode2);
                        ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                        ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1startDate', xbrliPrefix));
                        if NoOfPeriods = 1 then
                            ContextNode3.InnerText :=
                              StrSubstNo('%1-%2-%3',
                                (Date2DMY(PeriodStartDate, 3)),
                                CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                                CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2))
                        else
                            if NoOfPeriods > 1 then
                                ContextNode3.InnerText :=
                                  StrSubstNo('%1-%2-%3',
                                    (Date2DMY(PeriodStartDate, 3) + 1),
                                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));

                        /*DATE2DMY((PeriodEndDate + 1),3),
                        COPYSTR(FORMAT(100 + DATE2DMY((PeriodEndDate +1),2)),2),
                        COPYSTR(FORMAT(100 + DATE2DMY((PeriodStartDate + 1),1)),2));*/
                        ContextNode2.AppendChild(ContextNode3);
                        ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1endDate', xbrliPrefix));
                        ContextNode3.InnerText :=
                          StrSubstNo('%1-%2-%3',
                            Date2DMY(PeriodEndDate, 3),
                            CopyStr(Format(100 + Date2DMY(PeriodEndDate, 2)), 2),
                            CopyStr(Format(100 + Date2DMY(PeriodEndDate, 1)), 2));
                        ContextNode2.AppendChild(ContextNode3);
                        DurationContextNode.AppendChild(ContextNode2);
                        i += 1;
                        // END ELSE BEGIN
                    end else
                        if i = NoOfPeriods then begin
                            DurationContextNode := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NumericContextElemName), xbrliNamespace);
                            // XBRLManagement.AddAttribute(DurationContextNode,'id',STRSUBSTNO('dNC%1',i));
                            XBRLManagement.AddAttribute(DurationContextNode, 'id', 'Company_Current_AsOf');
                            if XBRLVersion = 'http://www.xbrl.org/2001/instance' then begin
                                // XBRLManagement.AddAttribute(DurationContextNode,'precision','18');
                                XBRLManagement.AddAttribute(DurationContextNode, 'decimals', '18');
                                if cwa then
                                    XBRLManagement.AddAttribute(DurationContextNode, 'cwa', 'true')
                                else
                                    XBRLManagement.AddAttribute(DurationContextNode, 'cwa', 'false');
                            end;
                            // InstantContextNode := XBRLInstanceDocument.CreateElement(STRSUBSTNO('%1%2',xbrliPrefix,NumericContextElemName),xbrliNamespace);
                            // XBRLManagement.AddAttribute(InstantContextNode,'id',STRSUBSTNO('iNC%1',i));
                            // IF XBRLVersion = 'http://www.xbrl.org/2001/instance' THEN BEGIN
                            // XBRLManagement.AddAttribute(InstantContextNode,'precision','18');
                            // IF cwa THEN
                            // XBRLManagement.AddAttribute(InstantContextNode,'cwa','true')
                            // ELSE
                            // XBRLManagement.AddAttribute(InstantContextNode,'cwa','false');

                            ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix));
                            ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix));
                            XBRLManagement.AddAttribute(ContextNode3, 'scheme', SchemeName);
                            ContextNode3.InnerText := SchemeIdentifier;
                            ContextNode2.AppendChild(ContextNode3);
                            DurationContextNode.AppendChild(ContextNode2);
                            ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                            ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1instant', xbrliPrefix));
                            ContextNode3.InnerText :=
                              StrSubstNo('%1-%2-%3',
                                Date2DMY(PeriodStartDate, 3),
                                CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                                CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                            ContextNode2.AppendChild(ContextNode3);
                            DurationContextNode.AppendChild(ContextNode2);
                        end;

                    if (XBRLVersion = 'http://www.xbrl.org/2001/instance') and (i >= 0) then begin
                        ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1unit', xbrliPrefix));
                        ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1measure', xbrliPrefix));
                        ContextNode3.InnerText := StrSubstNo('iso4217:%1', CurrencyCode);
                        ContextNode2.AppendChild(ContextNode3);
                        DurationContextNode.AppendChild(ContextNode2);
                    end;
                    RootNode.AppendChild(DurationContextNode);
                end;
                // For Prior period
                ContextNode4 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NonNumericContextElemName));
                XBRLManagement.AddAttribute(ContextNode4, 'id', 'Company_Prior_ForPeriod');
                ContextNode5 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix), xbrliNamespace);
                ContextNode6 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix), xbrliNamespace);
                XBRLManagement.AddAttribute(ContextNode6, 'scheme', SchemeName);
                ContextNode6.InnerText := SchemeIdentifier;
                ContextNode5.AppendChild(ContextNode6);
                ContextNode4.AppendChild(ContextNode5);
                ContextNode5 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                ContextNode7 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1startDate', xbrliPrefix));
                ContextNode7.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(CalcDate('-1Y', PeriodStartDate), 3),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                ContextNode5.AppendChild(ContextNode7);
                ContextNode7 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1endDate', xbrliPrefix));
                ContextNode7.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(CalcDate('-1Y', PeriodEndDate), 3),
                    CopyStr(Format(100 + Date2DMY(PeriodEndDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodEndDate, 1)), 2));
                ContextNode5.AppendChild(ContextNode7);
                ContextNode4.AppendChild(ContextNode5);
                RootNode.AppendChild(ContextNode4);

                ContextNode8 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NumericContextElemName));
                XBRLManagement.AddAttribute(ContextNode8, 'id', 'Company_Prior_AsOf');
                if XBRLVersion = 'http://www.xbrl.org/2001/instance' then begin
                    XBRLManagement.AddAttribute(ContextNode7, 'decimals', '18');
                end;
                ContextNode9 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix));
                ContextNode10 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix));
                XBRLManagement.AddAttribute(ContextNode10, 'scheme', SchemeName);
                ContextNode10.InnerText := SchemeIdentifier;
                ContextNode9.AppendChild(ContextNode10);
                ContextNode8.AppendChild(ContextNode9);
                ContextNode9 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                ContextNode10 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1instant', xbrliPrefix));
                ContextNode10.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(CalcDate('-1Y', PeriodStartDate), 3),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                ContextNode9.AppendChild(ContextNode10);
                ContextNode8.AppendChild(ContextNode9);
                RootNode.AppendChild(ContextNode8);
                // For Prior Period

                // For Consolidated Current period
                ContextNode11 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NonNumericContextElemName));
                XBRLManagement.AddAttribute(ContextNode11, 'id', 'Consolidated_Current_ForPeriod');
                ContextNode12 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix));
                ContextNode13 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix));
                XBRLManagement.AddAttribute(ContextNode13, 'scheme', SchemeName);
                ContextNode13.InnerText := SchemeIdentifier;
                ContextNode12.AppendChild(ContextNode13);
                ContextNode11.AppendChild(ContextNode12);
                ContextNode12 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                ContextNode14 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1startDate', xbrliPrefix));
                ContextNode14.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(PeriodStartDate, 3),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                ContextNode12.AppendChild(ContextNode14);
                ContextNode14 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1endDate', xbrliPrefix));
                ContextNode14.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(PeriodEndDate, 3),
                    CopyStr(Format(100 + Date2DMY(PeriodEndDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodEndDate, 1)), 2));
                ContextNode12.AppendChild(ContextNode14);
                ContextNode11.AppendChild(ContextNode12);
                RootNode.AppendChild(ContextNode11);

                ContextNode15 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NumericContextElemName));
                XBRLManagement.AddAttribute(ContextNode15, 'id', 'Consolidated_Current_AsOf');
                if XBRLVersion = 'http://www.xbrl.org/2001/instance' then begin
                    XBRLManagement.AddAttribute(ContextNode14, 'decimals', '18');
                end;
                ContextNode16 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix));
                ContextNode17 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix));
                XBRLManagement.AddAttribute(ContextNode17, 'scheme', SchemeName);
                ContextNode17.InnerText := SchemeIdentifier;
                ContextNode16.AppendChild(ContextNode17);
                ContextNode15.AppendChild(ContextNode16);
                ContextNode16 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                ContextNode17 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1instant', xbrliPrefix));
                ContextNode17.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(PeriodStartDate, 3),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                ContextNode16.AppendChild(ContextNode17);
                ContextNode15.AppendChild(ContextNode16);
                RootNode.AppendChild(ContextNode15);
                // For Consolidated Current Period

                // For Consolidated Prior Period
                ContextNode18 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NonNumericContextElemName));
                XBRLManagement.AddAttribute(ContextNode18, 'id', 'Consolidated_Prior_ForPeriod');
                ContextNode19 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix));
                ContextNode20 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix));
                XBRLManagement.AddAttribute(ContextNode20, 'scheme', SchemeName);
                ContextNode20.InnerText := SchemeIdentifier;
                ContextNode19.AppendChild(ContextNode20);
                ContextNode18.AppendChild(ContextNode19);
                ContextNode19 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                ContextNode21 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1startDate', xbrliPrefix));
                ContextNode21.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(CalcDate('-1Y', PeriodStartDate), 3),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                ContextNode19.AppendChild(ContextNode21);
                ContextNode21 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1endDate', xbrliPrefix));
                ContextNode21.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(CalcDate('-1Y', PeriodEndDate), 3),
                    CopyStr(Format(100 + Date2DMY(PeriodEndDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodEndDate, 1)), 2));
                ContextNode19.AppendChild(ContextNode21);
                ContextNode18.AppendChild(ContextNode19);
                RootNode.AppendChild(ContextNode18);

                ContextNode22 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NumericContextElemName));
                XBRLManagement.AddAttribute(ContextNode22, 'id', 'Consolidated_Prior_AsOf');
                if XBRLVersion = 'http://www.xbrl.org/2001/instance' then begin
                    XBRLManagement.AddAttribute(ContextNode21, 'decimals', '18');
                end;
                ContextNode23 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix));
                ContextNode24 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix));
                XBRLManagement.AddAttribute(ContextNode24, 'scheme', SchemeName);
                ContextNode24.InnerText := SchemeIdentifier;
                ContextNode23.AppendChild(ContextNode24);
                ContextNode22.AppendChild(ContextNode23);
                ContextNode23 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                ContextNode24 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1instant', xbrliPrefix));
                ContextNode24.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(CalcDate('-1Y', PeriodStartDate), 3),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                ContextNode23.AppendChild(ContextNode24);
                ContextNode22.AppendChild(ContextNode23);
                RootNode.AppendChild(ContextNode22);
                // For Consolidated Prior Period

                // For Reporting Options
                ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1%2', xbrliPrefix, NumericContextElemName));
                XBRLManagement.AddAttribute(ContextNode2, 'id', 'reporting_options');
                ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1entity', xbrliPrefix));
                ContextNode4 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1identifier', xbrliPrefix));
                XBRLManagement.AddAttribute(ContextNode4, 'scheme', SchemeName);
                ContextNode4.InnerText := SchemeIdentifier;
                ContextNode3.AppendChild(ContextNode4);
                ContextNode2.AppendChild(ContextNode3);
                ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1period', xbrliPrefix));
                ContextNode4 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1instant', xbrliPrefix));
                ContextNode4.InnerText :=
                  StrSubstNo('%1-%2-%3',
                    Date2DMY(PeriodStartDate, 3),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 2)), 2),
                    CopyStr(Format(100 + Date2DMY(PeriodStartDate, 1)), 2));
                ContextNode3.AppendChild(ContextNode4);
                ContextNode2.AppendChild(ContextNode3);
                ContextNode25 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1Scenario', xbrliPrefix));
                ContextNode2.AppendChild(ContextNode25);
                NewLineNode[1] := XBRLInstanceDocument.CreateElement('acra:isrestatement');
                if IsRestatement then
                    NewLineNode[1].InnerText := 'true'
                else
                    NewLineNode[1].InnerText := 'false';
                NewLineNode[2] := XBRLInstanceDocument.CreateElement('acra:isReClassification');
                if IsReClassification then
                    NewLineNode[2].InnerText := 'true'
                else
                    NewLineNode[2].InnerText := 'false';
                NewLineNode[3] := XBRLInstanceDocument.CreateElement('acra:isFirstFS');
                if IsFirstFS then
                    NewLineNode[3].InnerText := 'true'
                else
                    NewLineNode[3].InnerText := 'false';
                NewLineNode[4] := XBRLInstanceDocument.CreateElement('acra:isFirstXBRLFiling');
                if IsFirstXBRLFiling then
                    NewLineNode[4].InnerText := 'true'
                else
                    NewLineNode[4].InnerText := 'false';
                NewLineNode[5] := XBRLInstanceDocument.CreateElement('acra:isConsolidatedAccounts');
                if IsConsolidatedAccounts then
                    NewLineNode[5].InnerText := 'true'
                else
                    NewLineNode[5].InnerText := 'false';
                NewLineNode[6] := XBRLInstanceDocument.CreateElement('acra:currencyUnit');
                NewLineNode[6].InnerText := Format(CurrencyUnit);
                NewLineNode[7] := XBRLInstanceDocument.CreateElement('acra:currencyCode');
                NewLineNode[7].InnerText := Format(CurrencyCode);
                NewLineNode[8] := XBRLInstanceDocument.CreateElement('acra:SCEHiddenColumns');
                NewLineNode[9] := XBRLInstanceDocument.CreateElement('acra:periodcomparable');
                if PeriodComparable then
                    NewLineNode[9].InnerText := 'true'
                else
                    NewLineNode[9].InnerText := 'false';
                ContextNode25.AppendChild(NewLineNode[1]);
                ContextNode25.AppendChild(NewLineNode[2]);
                ContextNode25.AppendChild(NewLineNode[3]);
                ContextNode25.AppendChild(NewLineNode[4]);
                ContextNode25.AppendChild(NewLineNode[5]);
                ContextNode25.AppendChild(NewLineNode[6]);
                ContextNode25.AppendChild(NewLineNode[7]);
                ContextNode25.AppendChild(NewLineNode[8]);
                ContextNode25.AppendChild(NewLineNode[9]);
                RootNode.AppendChild(ContextNode2);
                // For Reporting Options

                if XBRLVersion = 'http://www.xbrl.org/2003/instance' then begin
                    ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1unit', xbrliPrefix));
                    // XBRLManagement.AddAttribute(ContextNode2,'id','currency');
                    XBRLManagement.AddAttribute(ContextNode2, 'id', 'monetary_unit');

                    ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1measure', xbrliPrefix));
                    ContextNode3.InnerText := StrSubstNo('iso4217:%1', CurrencyCode);
                    ContextNode2.AppendChild(ContextNode3);
                    RootNode.AppendChild(ContextNode2);
                    ContextNode2 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1unit', xbrliPrefix));
                    XBRLManagement.AddAttribute(ContextNode2, 'id', 'pure_unit');
                    ContextNode3 := XBRLInstanceDocument.CreateElement(StrSubstNo('%1measure', xbrliPrefix));
                    ContextNode3.InnerText := CurrencyCode;
                    ContextNode2.AppendChild(ContextNode3);
                    RootNode.AppendChild(ContextNode2);
                end;
                NonNumericContextElemName := 'contextRef';
                NumericContextElemName := 'contextRef';


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
                            if not XBRLTaxonomyLabel.FindFirst() then
                                Error(Text022, XBRLTaxonomyName);
                            XBRLTaxonomyLabel.SetRange(
                              "XBRL Taxonomy Line No.", XBRLTaxonomyLabel."XBRL Taxonomy Line No.");
                            XBRLTaxonomyLabels.SetTableView(XBRLTaxonomyLabel);
                            XBRLTaxonomyLabels.LookupMode := true;
                            if XBRLTaxonomyLabels.RunModal() = ACTION::LookupOK then begin
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
                                if XBRLTaxonomyLabel.IsEmpty() then
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
                    field(IsRestatement; IsRestatement)
                    {
                        ApplicationArea = XBRL;
                    }
                    field(IsReClassification; IsReClassification)
                    {
                        ApplicationArea = XBRL;
                    }
                    field(IsFirstFS; IsFirstFS)
                    {
                        ApplicationArea = XBRL;
                    }
                    field(IsFirstXBRLFiling; IsFirstXBRLFiling)
                    {
                        ApplicationArea = XBRL;
                    }
                    field(IsConsolidatedAccounts; IsConsolidatedAccounts)
                    {
                        ApplicationArea = XBRL;
                    }
                    field(CurrencyUnit; CurrencyUnit)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Currency Unit';
                        ToolTip = 'Specifies the currency unit.';
                    }
                    field(PeriodComparable; PeriodComparable)
                    {
                        ApplicationArea = XBRL;
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
        SchemeName := 'http://www.acra.gov.sg';
        SchemeIdentifier := '197200078R';
        XBRLTaxonomyName := 'ACRA3';
        LabelLanguage := 'en';
        CurrencyUnit := -3;
        CreateFile := true;
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

        FilterString := "XBRL Taxonomy Line".GetFilters();

        "XBRL Taxonomy Line".SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
        "XBRL Taxonomy Line".SetFilter(
          "Source Type", '<>%1', "XBRL Taxonomy Line"."Source Type"::"Not Applicable");
    end;

    trigger OnPostReport()
    var
        FileManagement: Codeunit "File Management";
        XMLDOMManagement: Codeunit "XML DOM Management";
        TempBlob: Codeunit "Temp Blob";
        XmlInStream: InStream;
        XmlOutStream: OutStream;
    begin
        if CreateFile then begin
            TempBlob.CreateInStream(XmlInStream);
            TempBlob.CreateOutStream(XmlOutStream);

            XMLDOMManagement.SaveXMLDocumentToOutStream(XmlOutStream, XBRLInstanceDocument.DocumentElement);
            FileManagement.DownloadFromStreamHandler(XmlInStream, Text024, '', Text001, Text025);
            Message(Text017, Text025);
        end;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        XBRLTaxonomy: Record "XBRL Taxonomy";
        XBRLSchema: Record "XBRL Schema";
        TempAmountBuf: Record "Entry No. Amount Buffer" temporary;
        XBRLManagement: Codeunit "XBRL Management";
        PeriodLength: DateFormula;
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
        LineNodes: array[50] of DotNet XmlNode;
        ContextNode4: DotNet XmlNode;
        ContextNode5: DotNet XmlNode;
        ContextNode6: DotNet XmlNode;
        ContextNode7: DotNet XmlNode;
        ContextNode8: DotNet XmlNode;
        ContextNode9: DotNet XmlNode;
        ContextNode10: DotNet XmlNode;
        ContextNode11: DotNet XmlNode;
        ContextNode12: DotNet XmlNode;
        ContextNode13: DotNet XmlNode;
        ContextNode14: DotNet XmlNode;
        ContextNode15: DotNet XmlNode;
        ContextNode16: DotNet XmlNode;
        ContextNode17: DotNet XmlNode;
        ContextNode18: DotNet XmlNode;
        ContextNode19: DotNet XmlNode;
        ContextNode20: DotNet XmlNode;
        ContextNode21: DotNet XmlNode;
        ContextNode22: DotNet XmlNode;
        ContextNode23: DotNet XmlNode;
        ContextNode24: DotNet XmlNode;
        IsRestatement: Boolean;
        IsReClassification: Boolean;
        IsFirstFS: Boolean;
        IsFirstXBRLFiling: Boolean;
        IsConsolidatedAccounts: Boolean;
        CurrencyUnit: Decimal;
        PeriodComparable: Boolean;
        ContextNode25: DotNet XmlNode;
        NewLineNode: array[50] of DotNet XmlNode;
        LabelCaptionLbl: Label 'Label';
        LineDescriptionCaptionLbl: Label 'Description';
        LineAmountCaptionLbl: Label 'Amount';
        PageCaptionLbl: Label 'Page';
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
                    More := Next() <> 0;
                end;
                NoteNode := XBRLInstanceDocument.CreateElement(NamespaceName, NodeName, XBRLSchema.targetNamespace);
                NoteNode.InnerText := BufTxt[1] + BufTxt[2];
                // IF XBRLTaxonomyLine."Numeric Context Period Type" = XBRLTaxonomyLine."Numeric Context Period Type"::Instant THEN
                // XBRLManagement.AddAttribute(NoteNode,NonNumericContextAttrName,'inNC0')
                // ELSE
                // XBRLManagement.AddAttribute(NoteNode,NonNumericContextAttrName,'dnNC0');
                XBRLManagement.AddAttribute(NoteNode, NonNumericContextAttrName, 'Company_Current_ForPeriod');
                RootNode.AppendChild(NoteNode);
                Clear(NoteNode);
            end;
        end;
    end;

    local procedure WriteLineToOutStr(String: Text[1024]; var OutStr: OutStream)
    var
        i: Integer;
        c: Char;
    begin
        for i := 1 to StrLen(String) do begin
            c := String[i];
            OutStr.Write(c);
        end;
    end;

    local procedure CopyXMLBody(var InStr: InStream; var OutStr: OutStream)
    var
        c: Char;
    begin
        repeat
            InStr.Read(c);
        until InStr.EOS or (c = '>');
        if not InStr.EOS then
            repeat
                InStr.Read(c);
                if c <> '<' then
                    OutStr.Write(c);
            until InStr.EOS or (c = '<');
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


#endif