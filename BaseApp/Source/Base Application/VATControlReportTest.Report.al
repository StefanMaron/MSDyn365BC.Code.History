report 31101 "VAT Control Report - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VATControlReportTest.rdlc';
    Caption = 'VAT Control Report - Test';

    dataset
    {
        dataitem(VATControlReportHeader; "VAT Control Report Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Closed by Document No. Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(CurrReport_PAGENO; CurrReport.PageNo)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(VATControlReportHeader_No; "No.")
            {
            }
            column(VATControlReportHeader_PeriodNo; "Period No.")
            {
            }
            column(VATControlReportHeader_Year; Year)
            {
            }
            column(VATControlReportHeader_StartDate; Format("Start Date", 0, '<Day,2>.<Month,2>.<Year>'))
            {
            }
            column(VATControlReportHeader_EndDate; Format("End Date", 0, '<Day,2>.<Month,2>.<Year>'))
            {
            }
            column(VATControlReportHeader_PerformCountryRegionCode; "Perform. Country/Region Code")
            {
            }
            column(VATControlReportHeader_VATStatementTemplateName; "VAT Statement Template Name")
            {
            }
            column(VATControlReportHeader_VATStatementName; "VAT Statement Name")
            {
            }
            column(VATControlReportHeader_ClosedbyDocumentNoFilter; GetFilter("Closed by Document No. Filter"))
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ReportCaption; ReportCaptionLbl)
            {
            }
            column(VATControlReportHeader_No_Caption; FieldCaption("No."))
            {
            }
            column(VATControlReportHeader_PeriodNo_Caption; FieldCaption("Period No."))
            {
            }
            column(VATControlReportHeader_Year_Caption; FieldCaption(Year))
            {
            }
            column(VATControlReportHeader_StartDate_Caption; FieldCaption("Start Date"))
            {
            }
            column(VATControlReportHeader_EndDate_Caption; FieldCaption("End Date"))
            {
            }
            column(VATControlReportHeader_PerformCountryRegionCode_Caption; FieldCaption("Perform. Country/Region Code"))
            {
            }
            column(VATControlReportHeader_VATStatementTemplateName_Caption; FieldCaption("VAT Statement Template Name"))
            {
            }
            column(VATControlReportHeader_VATStatementName_Caption; FieldCaption("VAT Statement Name"))
            {
            }
            column(VATControlReportHeader_ClosedbyDocumentNoFilter_Caption; FieldCaption("Closed by Document No. Filter"))
            {
            }
            column(VATControlReportBuffer_PostingDate_Caption; VATControlReportBuffer.FieldCaption("Original Document VAT Date"))
            {
            }
            column(VATControlReportBuffer_BirthDate_Caption; VATControlReportBuffer.FieldCaption("Birth Date"))
            {
            }
            column(VATControlReportBuffer_RatioUse_Caption; VATControlReportBuffer.FieldCaption("Ratio Use"))
            {
            }
            column(VATControlReportBuffer_CorrectionsForBadReceivable_Caption; VATControlReportBuffer.FieldCaption("Corrections for Bad Receivable"))
            {
            }
            dataitem(HeaderErrorCounter; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(ErrorText_Number_Header; ErrorText[Number])
                {
                }
                column(ErrorText_Number_HeaderCaption; ErrorTextLbl)
                {
                }
                column(HeaderErrorCounter_Number; Number)
                {
                }

                trigger OnPostDataItem()
                begin
                    ErrorCounter := 0;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, ErrorCounter);
                end;
            }
            dataitem(VATControlReportBuffer; "VAT Control Report Buffer")
            {
                DataItemTableView = SORTING("VAT Control Rep. Section Code", "Line No.");
                UseTemporary = true;
                column(VATControlReportBuffer_VATControlRepSectionCode; "VAT Control Rep. Section Code")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_PostingDate; Format("Original Document VAT Date", 0, '<Day,2>.<Month,2>.<Year>'))
                {
                }
                column(VATControlReportBuffer_BilltoPaytoNo; "Bill-to/Pay-to No.")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_VATRegistrationNo; "VAT Registration No.")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_RegistrationNo; "Registration No.")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_TaxRegistrationNo; "Tax Registration No.")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_DocumentNo; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_Type; Type)
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_VATBusPostingGroup; "VAT Bus. Posting Group")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_VATProdPostingGroup; "VAT Prod. Posting Group")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_VATRate; "VAT Rate")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_CommodityCode; "Commodity Code")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_SuppliesModeCode; "Supplies Mode Code")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_CorrectionsForBadReceivable; Format("Corrections for Bad Receivable"))
                {
                }
                column(VATControlReportBuffer_RatioUse; Format("Ratio Use"))
                {
                }
                column(VATControlReportBuffer_Name; Name)
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_BirthDate; Format("Birth Date", 0, '<Day,2>.<Month,2>.<Year>'))
                {
                }
                column(VATControlReportBuffer_Placeofstay; "Place of stay")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_Base1; "Base 1")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_Amount1; "Amount 1")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_Base2; "Base 2")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_Amount2; "Amount 2")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_Base3; "Base 3")
                {
                    IncludeCaption = true;
                }
                column(VATControlReportBuffer_Amount3; "Amount 3")
                {
                    IncludeCaption = true;
                }
                dataitem(LineErrorCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(ErrorText_Number__Line; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number__LineCaption; ErrorTextLbl)
                    {
                    }
                    column(LineErrorCounter_Number; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        TempVATCtrlRptBuf3: Record "VAT Control Report Buffer" temporary;
                    begin
                        if Number = 2 then begin
                            TempVATCtrlRptBuf3 := VATControlReportBuffer;
                            Clear(VATControlReportBuffer);
                            VATControlReportBuffer."VAT Control Rep. Section Code" := TempVATCtrlRptBuf3."VAT Control Rep. Section Code";
                            VATControlReportBuffer."Line No." := TempVATCtrlRptBuf3."Line No.";
                        end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if ReportPrintType = ReportPrintType::Detail then begin
                        if "VAT Control Rep. Section Code" = '' then
                            AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption("VAT Control Rep. Section Code")));

                        CopyBufferToLine(VATControlReportBuffer, VATCtrlRptLn);
                        CheckMandatoryFields;

                        if OnlyErrorLines and (ErrorCounter = 0) then
                            CurrReport.Skip;
                    end;

                    if (("Base 1" + "Amount 1") = 0) and
                       (("Base 2" + "Amount 2") = 0) and
                       (("Base 3" + "Amount 3") = 0)
                    then
                        CurrReport.Skip;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Period No." = 0 then
                    AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption("Period No.")));
                if Year = 0 then
                    AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption(Year)));
                if "Start Date" = 0D then
                    AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption("Start Date")));
                if "End Date" = 0D then
                    AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption("End Date")));

                case ReportPrintType of
                    ReportPrintType::Detail:
                        begin
                            VATCtrlRptLn.Reset;
                            VATCtrlRptLn.SetRange("Control Report No.", "No.");
                            // All, Export, Not Export
                            case ReportPrintEntries of
                                ReportPrintEntries::All:
                                    ;
                                ReportPrintEntries::Export:
                                    VATCtrlRptLn.SetRange("Exclude from Export", false);
                                ReportPrintEntries::"Not Export":
                                    VATCtrlRptLn.SetRange("Exclude from Export", true);
                            end;
                            // Open, Close, Open and Close
                            case Selection of
                                Selection::Open:
                                    VATCtrlRptLn.SetFilter("Closed by Document No.", '%1', '');
                                Selection::Closed:
                                    begin
                                        if GetFilter("Closed by Document No. Filter") <> '' then
                                            VATCtrlRptLn.SetFilter("Closed by Document No.", GetFilter("Closed by Document No. Filter"))
                                        else
                                            VATCtrlRptLn.SetFilter("Closed by Document No.", '<>%1', '');
                                    end;
                                Selection::"Open and Closed":
                                    begin
                                        if GetFilter("Closed by Document No. Filter") <> '' then
                                            VATCtrlRptLn.SetFilter("Closed by Document No.", GetFilter("Closed by Document No. Filter"))
                                        else
                                            VATCtrlRptLn.SetRange("Closed by Document No.");
                                    end;
                            end;
                            if VATCtrlRptLn.FindSet then
                                repeat
                                    case VATCtrlRptLn."VAT Control Rep. Section Code" of
                                        'A5', 'B3':
                                            begin
                                                // A5 and B3 section summary
                                                if not VATControlReportBuffer.Get(VATCtrlRptLn."VAT Control Rep. Section Code", 0) then begin
                                                    VATControlReportBuffer.Init;
                                                    VATControlReportBuffer."VAT Control Rep. Section Code" := VATCtrlRptLn."VAT Control Rep. Section Code";
                                                    VATControlReportBuffer."Line No." := 0;
                                                    VATControlReportBuffer.Insert;
                                                end;
                                                case VATCtrlRptLn."VAT Rate" of
                                                    VATCtrlRptLn."VAT Rate"::Base:
                                                        begin
                                                            VATControlReportBuffer."Base 1" += VATCtrlRptLn.Base;
                                                            VATControlReportBuffer."Amount 1" += VATCtrlRptLn.Amount;
                                                        end;
                                                    VATCtrlRptLn."VAT Rate"::Reduced:
                                                        begin
                                                            VATControlReportBuffer."Base 2" += VATCtrlRptLn.Base;
                                                            VATControlReportBuffer."Amount 2" += VATCtrlRptLn.Amount;
                                                        end;
                                                    VATCtrlRptLn."VAT Rate"::"Reduced 2":
                                                        begin
                                                            VATControlReportBuffer."Base 3" += VATCtrlRptLn.Base;
                                                            VATControlReportBuffer."Amount 3" += VATCtrlRptLn.Amount;
                                                        end;
                                                end;
                                                VATControlReportBuffer.Modify;
                                            end;
                                        else begin
                                                // other section codes
                                                CopyLineToBuffer(VATCtrlRptLn, VATControlReportBuffer);
                                                VATControlReportBuffer.Insert;
                                            end;
                                    end;
                                until VATCtrlRptLn.Next = 0;
                        end;
                    ReportPrintType::Export:
                        VATCtrlRptMgt.CreateBufferForExport(VATControlReportHeader, VATControlReportBuffer, false, Selection);
                    ReportPrintType::Summary:
                        VATCtrlRptMgt.CreateBufferForStatistics(VATControlReportHeader, VATControlReportBuffer, false);
                end;

                VATControlReportBuffer.Reset;
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
                    field(ReportPrintType; ReportPrintType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print';
                        OptionCaption = 'Detail,Export,Summary';
                        ToolTip = 'Specifies the preparation the document. A report request window for the document opens where you can specify what to include on the print-out.';

                        trigger OnValidate()
                        begin
                            LinesDetailEnable := (ReportPrintType = ReportPrintType::Detail);
                        end;
                    }
                    field(ReportPrintEntries; ReportPrintEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Entries';
                        Enabled = LinesDetailEnable;
                        OptionCaption = 'All,Export,Not Export';
                        ToolTip = 'Specifies to indicate that detailed documents will print.';
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Entries Selection';
                        OptionCaption = 'Open,Closed,Open and Closed';
                        ToolTip = 'Specifies if opened, closed or opened and closed VAT control report lines have to be printed.';
                    }
                    field(OnlyErrorLines; OnlyErrorLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print only lines with error';
                        Enabled = LinesDetailEnable;
                        ToolTip = 'Specifies if only lines with error has to be printed.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            LinesDetailEnable := (ReportPrintType = ReportPrintType::Detail);
        end;
    }

    labels
    {
    }

    var
        ReportCaptionLbl: Label 'VAT Control Report - Test';
        MustBeSpecifiedErr: Label '%1 must be specified.', Comment = '%1=FIELDCAPTION';
        PageCaptionLbl: Label 'Page';
        ErrorTextLbl: Label 'Warning!';
        VATCtrlRptLn: Record "VAT Control Report Line";
        VATCtrlRptMgt: Codeunit VATControlReportManagement;
        ErrorText: array[99] of Text;
        ErrorCounter: Integer;
        ReportPrintType: Option Detail,Export,Summary;
        ReportPrintEntries: Option All,Export,"Not Export";
        OnlyErrorLines: Boolean;
        [InDataSet]
        LinesDetailEnable: Boolean;
        Selection: Option Open,Closed,"Open and Closed";

    local procedure AddError(Text: Text)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure CopyBufferToLine(var TempVATCtrlRptBuf2: Record "VAT Control Report Buffer" temporary; var VATCtrlRptLn2: Record "VAT Control Report Line")
    begin
        with TempVATCtrlRptBuf2 do begin
            VATCtrlRptMgt.CopyBufferToLine(TempVATCtrlRptBuf2, VATCtrlRptLn2);

            if ("Base 1" <> 0) or ("Amount 1" <> 0) then begin
                VATCtrlRptLn2."VAT Rate" := "VAT Rate"::Base;
                VATCtrlRptLn2.Base := "Base 1";
                VATCtrlRptLn2.Amount := "Amount 1";
            end;
            if ("Base 2" <> 0) or ("Amount 2" <> 0) then begin
                VATCtrlRptLn2."VAT Rate" := "VAT Rate"::Reduced;
                VATCtrlRptLn2.Base := "Base 2";
                VATCtrlRptLn2.Amount := "Amount 2";
            end;
            if ("Base 3" <> 0) or ("Amount 3" <> 0) then begin
                VATCtrlRptLn2."VAT Rate" := "VAT Rate"::"Reduced 2";
                VATCtrlRptLn2.Base := "Base 3";
                VATCtrlRptLn2.Amount := "Amount 3";
            end;

            VATCtrlRptLn2.Name := Name;
            VATCtrlRptLn2."Birth Date" := "Birth Date";
            VATCtrlRptLn2."Place of stay" := "Place of stay";
        end;
    end;

    local procedure CopyLineToBuffer(var VATCtrlRptLn2: Record "VAT Control Report Line"; var TempVATCtrlRptBuf2: Record "VAT Control Report Buffer" temporary)
    begin
        with VATCtrlRptLn2 do begin
            VATCtrlRptMgt.CopyLineToBuffer(VATCtrlRptLn2, TempVATCtrlRptBuf2);

            case TempVATCtrlRptBuf2."VAT Rate" of
                TempVATCtrlRptBuf2."VAT Rate"::Base:
                    begin
                        TempVATCtrlRptBuf2."Base 1" := Base;
                        TempVATCtrlRptBuf2."Amount 1" := Amount;
                    end;
                TempVATCtrlRptBuf2."VAT Rate"::Reduced:
                    begin
                        TempVATCtrlRptBuf2."Base 2" := Base;
                        TempVATCtrlRptBuf2."Amount 2" := Amount;
                    end;
                TempVATCtrlRptBuf2."VAT Rate"::"Reduced 2":
                    begin
                        TempVATCtrlRptBuf2."Base 3" := Base;
                        TempVATCtrlRptBuf2."Amount 3" := Amount;
                    end;
            end;
        end;
    end;

    local procedure CheckMandatoryFields()
    begin
        with VATCtrlRptLn do begin
            if "VAT Control Rep. Section Code" <> 'A3' then
                CheckMandatoryField(FieldNo("VAT Registration No."), FieldCaption("VAT Registration No."), "VAT Registration No." = '')
            else
                if (Name = '') or ("Birth Date" = 0D) or ("Place of stay" = '') then
                    CheckMandatoryField(FieldNo("VAT Registration No."), FieldCaption("VAT Registration No."), "VAT Registration No." = '');

            CheckMandatoryField(FieldNo("Posting Date"), FieldCaption("Posting Date"), "Posting Date" = 0D);
            CheckMandatoryField(FieldNo("Document No."), FieldCaption("Document No."), "Document No." = '');
            CheckMandatoryField(FieldNo(Base), FieldCaption(Base), Base = 0);
            CheckMandatoryField(FieldNo(Amount), FieldCaption(Amount), Amount = 0);
            CheckMandatoryField(FieldNo("Commodity Code"), FieldCaption("Commodity Code"), "Commodity Code" = '');

            if "VAT Registration No." = '' then begin
                CheckMandatoryField(FieldNo(Name), FieldCaption(Name), Name = '');
                CheckMandatoryField(FieldNo("Birth Date"), FieldCaption("Birth Date"), "Birth Date" = 0D);
                CheckMandatoryField(FieldNo("Place of stay"), FieldCaption("Place of stay"), "Place of stay" = '');
            end;

            CheckMandatoryField(FieldNo("Ratio Use"), FieldCaption("Ratio Use"), not "Ratio Use");
        end;
    end;

    local procedure CheckMandatoryField(FieldNo: Integer; FieldCaption: Text; FieldIsEmpty: Boolean)
    begin
        if not FieldIsEmpty then
            exit;

        if not VATCtrlRptMgt.CheckMandatoryField(FieldNo, VATCtrlRptLn) then
            AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption));
    end;
}

