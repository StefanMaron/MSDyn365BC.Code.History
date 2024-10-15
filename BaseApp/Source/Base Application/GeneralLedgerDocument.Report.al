report 11763 "General Ledger Document"
{
    DefaultLayout = RDLC;
    RDLCLayout = './GeneralLedgerDocument.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'General Ledger Document (Obsolete)';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = SORTING("No.");

            trigger OnAfterGetRecord()
            begin
                GLReg := "G/L Register";
                CurrReport.Break();
            end;

            trigger OnPreDataItem()
            begin
                if "G/L Register".GetFilters = '' then
                    CurrReport.Break();
            end;
        }
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = SORTING("Document No.", "Posting Date");
            RequestFilterFields = "Entry No.", "Document No.";
            column(ReportName; ReportNameLbl)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(ShowDim; ShowDim)
            {
            }
            column(AccTransLiabilityCaption; AccTransLiabilityCaptionLbl)
            {
            }
            column(PostingLiabilityCaption; PostingLiabilityCaptionLbl)
            {
            }
            column(PostedByCaption; PostedByCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(VATRegistrationNo; StrSubstNo('%1: %2', CoInfo.FieldCaption("VAT Registration No."), CoInfo."VAT Registration No."))
            {
            }
            column(RegistrationNo; StrSubstNo('%1: %2', CoInfo.FieldCaption("Registration No."), CoInfo."Registration No."))
            {
            }
            column(UserFullName_GLEntry; UserFullName("User ID"))
            {
            }
            column(PostingDate_GLEntryCaption; PostingDateCaptionLbl)
            {
            }
            column(PostingDate_GLEntry; Format("Posting Date", 0, 4))
            {
            }
            column(DocumentDate_GLEntryCaption; DocumentDateCaptionLbl)
            {
            }
            column(DocumentDate_GLEntry; Format("Document Date", 0, 4))
            {
            }
            column(DocumentNo_GLEntryCaption; DocumentNoCaptionLbl)
            {
            }
            column(DocumentNo_GLEntry; "Document No.")
            {
            }
            column(GLAccountNo_GLEntryCaption; FieldCaption("G/L Account No."))
            {
            }
            column(GLAccountNo_GLEntry; "G/L Account No.")
            {
            }
            column(Description_GLEntryCaption; FieldCaption(Description))
            {
            }
            column(Description_GLEntry; Description)
            {
            }
            column(DebitAmount_GLEntryCaption; FieldCaption("Debit Amount"))
            {
            }
            column(DebitAmount_GLEntry; "Debit Amount")
            {
            }
            column(CreditAmount_GLEntryCaption; FieldCaption("Credit Amount"))
            {
            }
            column(CreditAmount_GLEntry; "Credit Amount")
            {
            }
            column(GlobalDimension1Code_GLEntryCaption; FieldCaption("Global Dimension 1 Code"))
            {
            }
            column(GlobalDimension1Code_GLEntry; "Global Dimension 1 Code")
            {
            }
            column(GlobalDimension2Code_GLEntryCaption; FieldCaption("Global Dimension 2 Code"))
            {
            }
            column(GlobalDimension2Code_GLEntry; "Global Dimension 2 Code")
            {
            }
            column(ExternalDocumentNo_GLEntryCaption; FieldCaption("External Document No."))
            {
            }
            column(ExternalDocumentNo_GLEntry; "External Document No.")
            {
            }
            column(EntryNo_GLEntryCaption; FieldCaption("Entry No."))
            {
            }
            column(EntryNo_GLEntry; "Entry No.")
            {
            }
            dataitem(DimensionLoop; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(DimText; DimText)
                {
                }
                column(DimensionsCaption; DimensionsCaptionLbl)
                {
                }
                column(DimensionLoop_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not DimSetEntry.Find('-') then
                            CurrReport.Break();
                    end else
                        if not Continue then
                            CurrReport.Break();

                    Clear(DimText);
                    Continue := false;
                    repeat
                        OldDimText := DimText;
                        if DimText = '' then
                            DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                        else
                            DimText :=
                              StrSubstNo(
                                '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                        if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                            DimText := OldDimText;
                            Continue := true;
                            exit;
                        end;
                    until DimSetEntry.Next = 0;
                end;

                trigger OnPreDataItem()
                begin
                    if not ShowDim then
                        CurrReport.Break();

                    DimSetEntry.Reset();
                    DimSetEntry.SetRange("Dimension Set ID", "G/L Entry"."Dimension Set ID");
                end;
            }

            trigger OnPreDataItem()
            begin
                if GLReg."No." <> 0 then
                    SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
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
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies when the dimensions is to be show';
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

    trigger OnPreReport()
    begin
        CoInfo.Get();
        FormatAddr.Company(CompanyAddr, CoInfo);
    end;

    var
        CoInfo: Record "Company Information";
        DimSetEntry: Record "Dimension Set Entry";
        GLReg: Record "G/L Register";
        User: Record User;
        FormatAddr: Codeunit "Format Address";
        ShowDim: Boolean;
        Continue: Boolean;
        DimText: Text;
        OldDimText: Text;
        CompanyAddr: array[8] of Text[100];
        ReportNameLbl: Label 'General Ledger Document';
        DocumentNoCaptionLbl: Label 'DOCUMENT NO.:';
        AccTransLiabilityCaptionLbl: Label 'Accounting transaction liability:';
        PostingLiabilityCaptionLbl: Label 'Posting liability:';
        PostingDateCaptionLbl: Label 'Posting date:';
        PostedByCaptionLbl: Label 'Posted by:';
        DocumentDateCaptionLbl: Label 'Document Date:';
        PageCaptionLbl: Label 'Page:';
        DimensionsCaptionLbl: Label 'Dimensions';
        UnknownUserTxt: Label 'Unknown User ID %1', Comment = '%1=USERID';

    [Scope('OnPrem')]
    procedure UserFullName(ID: Code[50]): Text[100]
    begin
        if ID = '' then
            exit('');

        if User."User Name" = ID then
            exit(User."Full Name");

        User.SetCurrentKey("User Name");
        User.SetRange("User Name", ID);
        if User.FindFirst then
            exit(User."Full Name");

        exit(StrSubstNo(UnknownUserTxt, ID));
    end;
}

