report 5602 "Fixed Asset Journal - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssetJournalTest.rdlc';
    Caption = 'Fixed Asset Journal - Test';

    dataset
    {
        dataitem("FA Journal Batch"; "FA Journal Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(FA_Journal_Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(FA_Journal_Batch_Name; Name)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                PrintOnlyIfDetail = true;
                column(FA_Journal_Batch__Name; "FA Journal Batch".Name)
                {
                }
                column(FA_Journal_Batch___Journal_Template_Name_; "FA Journal Batch"."Journal Template Name")
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(FA_Journal_Line__TABLECAPTION__________FAJnlLineFilter; "FA Journal Line".TableCaption + ': ' + FAJnlLineFilter)
                {
                }
                column(FAJnlLineFilter; FAJnlLineFilter)
                {
                }
                column(DeprUntilFAPostingDate; DeprUntilFAPostingDate)
                {
                }
                column(FA_Journal_Batch__NameCaption; FA_Journal_Batch__NameCaptionLbl)
                {
                }
                column(FA_Journal_Batch___Journal_Template_Name_Caption; "FA Journal Batch".FieldCaption("Journal Template Name"))
                {
                }
                column(Fixed_Asset_Journal___TestCaption; Fixed_Asset_Journal___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(FA_Journal_Line__Depreciation_Book_Code_Caption; "FA Journal Line".FieldCaption("Depreciation Book Code"))
                {
                }
                column(FA_Journal_Line__FA_Posting_Date_Caption; FA_Journal_Line__FA_Posting_Date_CaptionLbl)
                {
                }
                column(FA_Journal_Line__Document_Type_Caption; "FA Journal Line".FieldCaption("Document Type"))
                {
                }
                column(FA_Journal_Line__Document_No__Caption; "FA Journal Line".FieldCaption("Document No."))
                {
                }
                column(FA_Journal_Line__FA_No__Caption; "FA Journal Line".FieldCaption("FA No."))
                {
                }
                column(FA_Journal_Line__FA_Posting_Type_Caption; "FA Journal Line".FieldCaption("FA Posting Type"))
                {
                }
                column(FA_Journal_Line_DescriptionCaption; "FA Journal Line".FieldCaption(Description))
                {
                }
                column(FA_Journal_Line_AmountCaption; "FA Journal Line".FieldCaption(Amount))
                {
                }
                column(FA_Journal_Line__No__of_Depreciation_Days_Caption; "FA Journal Line".FieldCaption("No. of Depreciation Days"))
                {
                }
                column(FA_Journal_Line__Depr__until_FA_Posting_Date_Caption; "FA Journal Line".FieldCaption("Depr. until FA Posting Date"))
                {
                }
                dataitem("FA Journal Line"; "FA Journal Line")
                {
                    DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                    DataItemLinkReference = "FA Journal Batch";
                    DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "FA Posting Date";
                    column(FA_Journal_Line__Depreciation_Book_Code_; "Depreciation Book Code")
                    {
                    }
                    column(FA_Journal_Line__FA_Posting_Date_; Format("FA Posting Date"))
                    {
                    }
                    column(FA_Journal_Line__Document_Type_; "Document Type")
                    {
                    }
                    column(FA_Journal_Line__Document_No__; "Document No.")
                    {
                    }
                    column(FA_Journal_Line__FA_No__; "FA No.")
                    {
                    }
                    column(FA_Journal_Line__FA_Posting_Type_; "FA Posting Type")
                    {
                    }
                    column(FA_Journal_Line_Description; Description)
                    {
                    }
                    column(FA_Journal_Line_Amount; Amount)
                    {
                    }
                    column(FA_Journal_Line__No__of_Depreciation_Days_; "No. of Depreciation Days")
                    {
                    }
                    column(FA_Journal_Line__Depr__until_FA_Posting_Date_; "Depr. until FA Posting Date")
                    {
                    }
                    column(FA_Journal_Line_Line_No_; "Line No.")
                    {
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(ErrorText_Number_; ErrorText[Number])
                        {
                        }
                        column(Warning_Caption; Warning_CaptionLbl)
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

                    trigger OnAfterGetRecord()
                    begin
                        if "FA No." <> '' then begin
                            if "FA Posting Date" = 0D then
                                AddError(
                                  StrSubstNo(
                                    Text001,
                                    FieldCaption("FA Posting Date")))
                            else begin
                                if "FA Posting Date" <> NormalDate("FA Posting Date") then
                                    AddError(
                                      StrSubstNo(
                                        Text002,
                                        FieldCaption("FA Posting Date")));
                                if not ("FA Posting Date" in [00020101D .. 99981231D]) then
                                    AddError(
                                      StrSubstNo(
                                        Text003,
                                        FieldCaption("FA Posting Date")));
                                if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                                    if UserId <> '' then
                                        if UserSetup.Get(UserId) then begin
                                            AllowPostingFrom := UserSetup."Allow FA Posting From";
                                            AllowPostingTo := UserSetup."Allow FA Posting To";
                                        end;
                                    if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                                        FASetup.Get();
                                        AllowPostingFrom := FASetup."Allow FA Posting From";
                                        AllowPostingTo := FASetup."Allow FA Posting To";
                                    end;
                                    if AllowPostingTo = 0D then
                                        AllowPostingTo := 99981231D;
                                end;
                                if ("FA Posting Date" < AllowPostingFrom) or
                                   ("FA Posting Date" > AllowPostingTo)
                                then
                                    AddError(
                                      StrSubstNo(
                                        Text003,
                                        FieldCaption("FA Posting Date")));
                            end;

                            if "Document No." = '' then
                                AddError(StrSubstNo(Text001, FieldCaption("Document No.")));

                            if "Depreciation Book Code" = '' then
                                AddError(
                                  StrSubstNo(Text001, FieldCaption("Depreciation Book Code")));
                            if "Depreciation Book Code" = "Duplicate in Depreciation Book" then
                                AddError(
                                  StrSubstNo(
                                    Text004,
                                    FieldCaption("Depreciation Book Code"),
                                    FieldCaption("Duplicate in Depreciation Book")));
                            if not FA.Get("FA No.") then begin
                                AddError(
                                  StrSubstNo(
                                    Text005, FA.TableCaption, "FA No."));
                                FA.Init();
                            end;
                            if FA.Blocked then
                                AddError(
                                  StrSubstNo(
                                    Text006,
                                    FA.FieldCaption(Blocked), false, FA.TableCaption, "FA No."));
                            if FA.Inactive then
                                AddError(
                                  StrSubstNo(
                                    Text006,
                                    FA.FieldCaption(Inactive), false, FA.TableCaption, "FA No."));

                            if not DeprBook.Get("Depreciation Book Code") then begin
                                AddError(
                                  StrSubstNo(
                                    Text005,
                                    DeprBook.TableCaption,
                                    "Depreciation Book Code"));
                                DeprBook.Init();
                            end;
                            if not FADeprBook.Get("FA No.", "Depreciation Book Code") then begin
                                AddError(
                                  StrSubstNo(
                                    Text007, FADeprBook.TableCaption, "FA No.", "Depreciation Book Code"));
                                FADeprBook.Init();
                            end;
                            if not FA."Budgeted Asset" then
                                CheckFAIntegration;
                            if "FA Error Entry No." > 0 then
                                CheckErrorNo;
                            CheckConsistency;
                            if not DeprBook."Allow Identical Document No." and
                               ("Depreciation Book Code" <> '') and ("Document No." <> '')
                            then
                                CheckFADocNo;
                        end;

                        if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                            AddError(DimMgt.GetDimCombErr);

                        TableID[1] := DATABASE::"Fixed Asset";
                        No[1] := "FA No.";
                        if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                            AddError(DimMgt.GetDimValuePostingErr);

                        DeprUntilFAPostingDate := Format("Depr. until FA Posting Date");
                    end;

                    trigger OnPreDataItem()
                    begin
                        FAJnlTemplate.Get("FA Journal Batch"."Journal Template Name");
                        if FAJnlTemplate.Recurring then begin
                            if GetFilter("FA Posting Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    FieldCaption("FA Posting Date")));
                            SetRange("FA Posting Date", 0D, WorkDate);
                            if GetFilter("Expiration Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    FieldCaption("Expiration Date")));
                            SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate);
                        end;

                        Clear(Amount);
                    end;
                }
            }
        }
    }

    requestpage
    {

        layout
        {
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
        FAJnlLineFilter := "FA Journal Line".GetFilters;
    end;

    var
        Text000: Label '%1 cannot be filtered when you post recurring journals.';
        Text001: Label '%1 must be specified.';
        Text002: Label '%1 cannot be a closing date.';
        Text003: Label '%1 is not within your range of allowed posting dates.';
        Text004: Label '%1 is not different than %2.';
        Text005: Label '%1 %2 does not exist.';
        Text006: Label '%1 must be %2 for %3 %4.';
        Text007: Label '%1 %2 %3 does not exist.';
        Text008: Label 'When G/L integration is activated, %1 must not be specified in the FA journal.';
        Text009: Label 'must not be specified when %1 is specified.';
        Text010: Label 'must not be specified together with %1 = %2.';
        Text011: Label '%1 must not be specified when %2 is a %3.';
        Text012: Label 'Insurance integration is not activated for %1 %2.';
        Text013: Label '%1 must be identical to %2.';
        FAJnlTemplate: Record "FA Journal Template";
        FA: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        UserSetup: Record "User Setup";
        FASetup: Record "FA Setup";
        DimMgt: Codeunit DimensionManagement;
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        GLIntegration: Boolean;
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        FAJnlLineFilter: Text;
        FieldErrorText: Text[100];
        DeprUntilFAPostingDate: Text[30];
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        Text014: Label '%1 %2 already exists.';
        FA_Journal_Batch__NameCaptionLbl: Label 'Journal Batch';
        Fixed_Asset_Journal___TestCaptionLbl: Label 'Fixed Asset Journal - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        FA_Journal_Line__FA_Posting_Date_CaptionLbl: Label 'FA Posting Date';
        Warning_CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure CheckFAIntegration()
    begin
        with "FA Journal Line" do begin
            case "FA Posting Type" of
                "FA Posting Type"::"Acquisition Cost":
                    GLIntegration := DeprBook."G/L Integration - Acq. Cost";
                "FA Posting Type"::Depreciation:
                    GLIntegration := DeprBook."G/L Integration - Depreciation";
                "FA Posting Type"::"Write-Down":
                    GLIntegration := DeprBook."G/L Integration - Write-Down";
                "FA Posting Type"::Appreciation:
                    GLIntegration := DeprBook."G/L Integration - Appreciation";
                "FA Posting Type"::"Custom 1":
                    GLIntegration := DeprBook."G/L Integration - Custom 1";
                "FA Posting Type"::"Custom 2":
                    GLIntegration := DeprBook."G/L Integration - Custom 2";
                "FA Posting Type"::Disposal:
                    GLIntegration := DeprBook."G/L Integration - Disposal";
                "FA Posting Type"::Maintenance:
                    GLIntegration := DeprBook."G/L Integration - Maintenance";
                "FA Posting Type"::"Salvage Value":
                    GLIntegration := false;
            end;
            if GLIntegration then
                AddError(
                  StrSubstNo(
                    Text008, Format("FA Posting Type")));

            if DeprBook."G/L Integration - Depreciation" then begin
                if "Depr. until FA Posting Date" then
                    AddError(
                      StrSubstNo(
                        Text008,
                        Format(FieldCaption("Depr. until FA Posting Date"))));
                if "Depr. Acquisition Cost" then
                    AddError(
                      StrSubstNo(
                        Text008,
                        Format(FieldCaption("Depr. Acquisition Cost"))));
            end;
        end;
    end;

    local procedure CheckErrorNo()
    begin
        with "FA Journal Line" do begin
            FieldErrorText :=
              '%1 ' +
              StrSubstNo(
                Text009,
                Format(FieldCaption("FA Error Entry No.")));
            if "Depr. until FA Posting Date" then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Depr. until FA Posting Date"))));
            if "Depr. Acquisition Cost" then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Depr. Acquisition Cost"))));
            if "Duplicate in Depreciation Book" <> '' then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Duplicate in Depreciation Book"))));
            if "Use Duplication List" then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Use Duplication List"))));
            if "Salvage Value" <> 0 then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Salvage Value"))));
            if "Insurance No." <> '' then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Insurance No."))));
            if "Budgeted FA No." <> '' then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Budgeted FA No."))));
            if "Recurring Method" > 0 then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Recurring Method"))));
            if "FA Posting Type" = "FA Posting Type"::Maintenance then
                AddError(StrSubstNo(FieldErrorText, Format("FA Posting Type")));
        end;
    end;

    local procedure CheckConsistency()
    begin
        with "FA Journal Line" do begin
            FieldErrorText :=
              '%1 ' +
              StrSubstNo(
                Text010,
                Format(FieldCaption("FA Posting Type")), Format("FA Posting Type"));
            if "FA Posting Type" <> "FA Posting Type"::"Acquisition Cost" then begin
                if "Depr. Acquisition Cost" then
                    AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Depr. Acquisition Cost"))));
                if "Salvage Value" <> 0 then
                    AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Salvage Value"))));
                if (Quantity <> 0) and ("FA Posting Type" <> "FA Posting Type"::Maintenance) then
                    AddError(StrSubstNo(FieldErrorText, Format(FieldCaption(Quantity))));
                if "Insurance No." <> '' then
                    AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Insurance No."))));
            end;

            if ("FA Posting Type" = "FA Posting Type"::Maintenance) and
               "Depr. until FA Posting Date"
            then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Depr. until FA Posting Date"))));
            if ("FA Posting Type" <> "FA Posting Type"::Maintenance) and ("Maintenance Code" <> '') then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("Maintenance Code"))));

            if ("FA Posting Type" <> "FA Posting Type"::Depreciation) and
               ("FA Posting Type" <> "FA Posting Type"::"Custom 1") and
               ("No. of Depreciation Days" <> 0)
            then
                AddError(StrSubstNo(FieldErrorText, Format(FieldCaption("No. of Depreciation Days"))));
            if "FA Posting Type" = "FA Posting Type"::Disposal then begin
                if "FA Reclassification Entry" then
                    AddError(
                      StrSubstNo(FieldErrorText, Format(FieldCaption("FA Reclassification Entry"))));
                if "Budgeted FA No." <> '' then
                    AddError(
                      StrSubstNo(FieldErrorText, Format(FieldCaption("Budgeted FA No."))));
            end;

            if FA."Budgeted Asset" and ("Budgeted FA No." <> '') then
                AddError(
                  StrSubstNo(
                    Text011,
                    Format(FieldCaption("Budgeted FA No.")), Format(FieldCaption("FA No.")),
                    Format(FA.FieldCaption("Budgeted Asset"))));

            FASetup.Get();
            if ("FA Posting Type" = "FA Posting Type"::"Acquisition Cost") and
               ("Insurance No." <> '') and (DeprBook.Code <> FASetup."Insurance Depr. Book")
            then
                AddError(
                  StrSubstNo(
                    Text012,
                    Format(FieldCaption("Depreciation Book Code")), Format("Depreciation Book Code")));

            if DeprBook."Use Same FA+G/L Posting Dates" and
               ("Posting Date" <> "FA Posting Date") and ("Posting Date" <> 0D)
            then
                AddError(
                  StrSubstNo(
                    Text013,
                    Format(FieldCaption("Posting Date")), Format(FieldCaption("FA Posting Date"))));
        end;
    end;

    local procedure CheckFADocNo()
    var
        OldFALedgEntry: Record "FA Ledger Entry";
        OldMaintenanceLedgEntry: Record "Maintenance Ledger Entry";
    begin
        with "FA Journal Line" do
            if "FA Posting Type" <> "FA Posting Type"::Maintenance then begin
                OldFALedgEntry.SetCurrentKey(
                  "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Document No.");
                OldFALedgEntry.SetRange("FA No.", "FA No.");
                OldFALedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                OldFALedgEntry.SetRange("FA Posting Category", OldFALedgEntry."FA Posting Category"::" ");
                OldFALedgEntry.SetRange("FA Posting Type", ConvertToLedgEntry("FA Journal Line"));
                OldFALedgEntry.SetRange("Document No.", "Document No.");
                if OldFALedgEntry.FindFirst then
                    AddError(
                      StrSubstNo(
                        Text014,
                        Format(FieldCaption("Document No.")), Format("Document No.")));
            end else begin
                OldMaintenanceLedgEntry.SetCurrentKey(
                  "FA No.", "Depreciation Book Code", "Document No.");
                OldMaintenanceLedgEntry.SetRange("FA No.", "FA No.");
                OldMaintenanceLedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                OldMaintenanceLedgEntry.SetRange("Document No.", "Document No.");
                if OldMaintenanceLedgEntry.FindFirst then
                    AddError(
                      StrSubstNo(
                        Text014,
                        Format(FieldCaption("Document No.")), Format("Document No.")));
            end;
    end;
}

