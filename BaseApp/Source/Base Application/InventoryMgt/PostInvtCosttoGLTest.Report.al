report 1003 "Post Invt. Cost to G/L - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryMgt/PostInvtCosttoGLTest.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Post Invt. Cost to G/L - Test';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            PrintOnlyIfDetail = true;
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text003_SELECTSTR_PostMethod___1_Text005__; StrSubstNo(PostedPostingTypeTxt, SelectStr(PostMethod + 1, PostingTypeTxt)))
            {
            }
            column(DocNo; DocNo)
            {
            }
            column(PostMethod; PostMethod)
            {
            }
            column(ItemValueEntry_TABLECAPTION__________ValueEntryFilter; ItemValueEntry.TableCaption + ': ' + ValueEntryFilter)
            {
            }
            column(ValueEntryFilter; ValueEntryFilter)
            {
            }
            column(Post_Inventory_Cost_to_G_L___TestCaption; Post_Inventory_Cost_to_G_L___TestCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(ItemValueEntry__Item_Ledger_Entry_No__Caption; ItemValueEntry__Item_Ledger_Entry_No__CaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf__Value_Entry_No__Caption; TempInvtPostToGLTestBuf__Value_Entry_No__CaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf_AmountCaption; TempInvtPostToGLTestBuf_AmountCaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf_DescriptionCaption; TempInvtPostToGLTestBuf_DescriptionCaptionLbl)
            {
            }
            column(AccNameCaption; AccNameCaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf__Account_No__Caption; TempInvtPostToGLTestBuf__Account_No__CaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf__Document_No__Caption; TempInvtPostToGLTestBuf__Document_No__CaptionLbl)
            {
            }
            column(ItemValueEntry__Entry_Type_Caption; ItemValueEntry__Entry_Type_CaptionLbl)
            {
            }
            column(ItemValueEntry__Item_Ledger_Entry_Type_Caption; ItemValueEntry__Item_Ledger_Entry_Type_CaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf__Posting_Date_Caption; TempInvtPostToGLTestBuf__Posting_Date_CaptionLbl)
            {
            }
            column(ItemValueEntry__Item_No__Caption; ItemValueEntry__Item_No__CaptionLbl)
            {
            }
            dataitem(PostValueEntryToGL; "Post Value Entry to G/L")
            {
                DataItemTableView = SORTING("Item No.", "Posting Date");
                RequestFilterFields = "Item No.", "Posting Date";

                trigger OnAfterGetRecord()
                begin
                    ItemValueEntry.Get("Value Entry No.");

                    with ItemValueEntry do begin
                        if "Item Ledger Entry No." = 0 then begin
                            TempCapValueEntry."Entry No." := "Entry No.";
                            TempCapValueEntry."Order Type" := "Order Type";
                            TempCapValueEntry."Order No." := "Order No.";
                            TempCapValueEntry.Insert();
                        end;
                        if ("Item Ledger Entry No." = 0) or not Inventoriable then
                            CurrReport.Skip();
                    end;

                    FillInvtPostToGLTestBuf(ItemValueEntry);
                end;

                trigger OnPostDataItem()
                begin
                    TempCapValueEntry.SetCurrentKey("Order Type", "Order No.");
                    if TempCapValueEntry.Find('-') then
                        repeat
                            ItemValueEntry.Get(TempCapValueEntry."Entry No.");
                            FillInvtPostToGLTestBuf(ItemValueEntry);
                        until TempCapValueEntry.Next() = 0;

                    if PostMethod = PostMethod::"per Posting Group" then begin
                        InvtPostToGL.SetGenJnlBatch(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        InvtPostToGL.PostInvtPostBufPerPostGrp(DocNo, '');
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    InvtPostToGL.SetRunOnlyCheck(false, true, true);
                    TempCapValueEntry.DeleteAll();
                    OnAfterPostValueEntryToGLOnPreDataItem(PostValueEntryToGL, CompanyName);
                end;
            }
            dataitem(InvtPostToGLTestBuf; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(TempInvtPostToGLTestBuf_Amount; TempInvtPostToGLTestBuf.Amount)
                {
                }
                column(TempInvtPostToGLTestBuf_Description; TempInvtPostToGLTestBuf.Description)
                {
                }
                column(AccName; AccName)
                {
                }
                column(TempInvtPostToGLTestBuf__Account_No__; TempInvtPostToGLTestBuf."Account No.")
                {
                }
                column(TempInvtPostToGLTestBuf__Document_No__; TempInvtPostToGLTestBuf."Document No.")
                {
                }
                column(TempInvtPostToGLTestBuf__Posting_Date_; Format(TempInvtPostToGLTestBuf."Posting Date"))
                {
                }
                column(TempInvtPostToGLTestBuf__Value_Entry_No__; TempInvtPostToGLTestBuf."Value Entry No.")
                {
                }
                column(ItemValueEntry__Item_Ledger_Entry_Type_; ItemValueEntry."Item Ledger Entry Type")
                {
                }
                column(ItemValueEntry__Entry_Type_; ItemValueEntry."Entry Type")
                {
                }
                column(ItemValueEntry__Item_Ledger_Entry_No__; ItemValueEntry."Item Ledger Entry No.")
                {
                }
                column(ItemValueEntry__Item_No__; ItemValueEntry."Item No.")
                {
                }
                column(Line_No_; TempInvtPostToGLTestBuf."Line No.")
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Number; Number)
                    {
                    }
                    column(DimensionsCaption; DimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.FindSet() then
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
                        until DimSetEntry.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();

                        DimSetEntry.SetRange("Dimension Set ID", TempInvtPostToGLTestBuf."Dimension Set ID");
                    end;
                }
                dataitem(ErrorLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
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
                var
                    DimMgt: Codeunit DimensionManagement;
                    UserSetupManagement: Codeunit "User Setup Management";
                    TableID: array[10] of Integer;
                    No: array[10] of Code[20];
                    WrongEntryTypeComb: Boolean;
                    TempErrorText: Text[250];
                begin
                    with TempInvtPostToGLTestBuf do begin
                        if Number = 1 then
                            Find('-')
                        else
                            Next();

                        AccName := '';

                        if "Value Entry No." <> 0 then begin
                            ItemValueEntry.Get("Value Entry No.");
                            WrongEntryTypeComb := not CheckEntryCombination(ItemValueEntry);
                        end else
                            Clear(ItemValueEntry);

                        if CheckPostingSetup(TempInvtPostToGLTestBuf) and not WrongEntryTypeComb then begin
                            if "Account No." = '' then
                                if "Invt. Posting Group Code" <> '' then
                                    AddError(
                                      StrSubstNo(
                                        Text012, GetAccountName(), InvtPostSetup.TableCaption(), "Location Code", "Invt. Posting Group Code"))
                                else
                                    AddError(
                                      StrSubstNo(
                                        Text012, GetAccountName(), GenPostSetup.TableCaption(), "Gen. Bus. Posting Group", "Gen. Prod. Posting Group"));

                            if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                                AddError(TempErrorText);

                            if "Account No." <> '' then
                                CheckGLAcc(TempInvtPostToGLTestBuf);

                            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                                AddError(DimMgt.GetDimCombErr());

                            TableID[1] := DimMgt.TypeToTableID1(0);
                            No[1] := "Account No.";
                            TableID[2] := DimMgt.TypeToTableID1(0);
                            No[2] := '';
                            TableID[3] := DATABASE::Job;
                            No[3] := '';
                            TableID[4] := DATABASE::"Salesperson/Purchaser";
                            No[4] := '';
                            TableID[5] := DATABASE::Campaign;
                            No[5] := '';
                            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                                AddError(DimMgt.GetDimValuePostingErr());
                        end;
                    end;

                    if ShowOnlyWarnings and (ErrorCounter = 0) then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    InvtPostToGL.GetTempInvtPostToGLTestBuf(TempInvtPostToGLTestBuf);
                    SetRange(Number, 1, TempInvtPostToGLTestBuf.Count);
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.GetRecordOnce();
                if not GLSetup."Journal Templ. Name Mandatory" then
                    case PostMethod of
                        PostMethod::"per Posting Group":
                            if DocNo = '' then
                                Error(
                                  EnterWhenPostingErr,
                                  ItemValueEntry.FieldCaption("Document No."), SelectStr(PostMethod + 1, PostingTypeTxt));
                        PostMethod::"per Entry":
                            if DocNo <> '' then
                                Error(
                                  DoNotEnterWhenPostingErr,
                                  ItemValueEntry.FieldCaption("Document No."), SelectStr(PostMethod + 1, PostingTypeTxt));
                    end;
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
                    field(PostingMethod; PostMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Method';
                        OptionCaption = 'Per Posting Group,Per Entry';
                        ToolTip = 'Specifies if the batch job tests the posting of inventory value to the general ledger per inventory posting group or per posted value entry. If you post per entry, you achieve a detailed specification of how the inventory affects the general ledger.';
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                    }
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies that the dimensions for each entry or posting group are included.';
                    }
                    field(ShowOnlyWarnings; ShowOnlyWarnings)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Only Warnings';
                        ToolTip = 'Specifies that only the entries that produce errors are included. If you do not select this check box, the report will show all entries that could be posted to the general ledger.';
                    }
                    field(JnlTemplateName; GenJnlLineReq."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnValidate()
                        begin
                            GenJnlLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JnlBatchName; GenJnlLineReq."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJnlManagement.SetJnlBatchName(GenJnlLineReq);
                            if GenJnlLineReq."Journal Batch Name" <> '' then
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLineReq."Journal Batch Name" <> '' then begin
                                GenJnlLineReq.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.GetRecordOnce();
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforePreReport(PostValueEntryToGL, ItemValueEntry);

        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            if GenJnlLineReq."Journal Template Name" = '' then
                Error(MissingJournalFieldErr, GenJnlLineReq.FieldCaption("Journal Template Name"));
            if GenJnlLineReq."Journal Batch Name" = '' then
                Error(MissingJournalFieldErr, GenJnlLineReq.FieldCaption("Journal Batch Name"));

            Clear(NoSeriesMgt);
            Clear(DocNo);
            GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            DocNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", 0D, true);
        end;

        ValueEntryFilter := PostValueEntryToGL.GetFilters();
    end;

    var
        EnterWhenPostingErr: Label 'Please enter a %1 when posting %2.', Comment = '%1 - field caption, %2 - posting type';
        DoNotEnterWhenPostingErr: Label 'Do not enter a %1 when posting %2.', Comment = '%1 - field caption, %2 - posting type';
        FieldCombinationErr: Label 'The following combination %1 = %2, %3 = %4, and %5 = %6 is not allowed.', Comment = '%1, %3, %5 - field captions, %2, %4, %6 - field values';
        PostedPostingTypeTxt: Label 'Posted %1', Comment = '%1 - posting type';
        PostingTypeTxt: Label 'per Posting Group,per Entry';
        DoesNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 - field caption, %2 - field value';
        MustBeForErr: Label '%1 must be %2 for %3 %4.', Comment = '%1 and %3 - field captions, %2 and %4 - field values';
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        TempInvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer" temporary;
        TempCapValueEntry: Record "Value Entry" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        ItemValueEntry: Record "Value Entry";
        InvtPostSetup: Record "Inventory Posting Setup";
        GenPostSetup: Record "General Posting Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLineReq: Record "Gen. Journal Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        InvtPostToGL: Codeunit "Inventory Posting To G/L";
        PostMethod: Option "per Posting Group","per Entry";
        DocNo: Code[20];
        ValueEntryFilter: Text;
        AccName: Text[100];
        ErrorText: array[50] of Text[250];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowDim: Boolean;
        Continue: Boolean;
        ShowOnlyWarnings: Boolean;
        ErrorCounter: Integer;
        [InDataSet]
        IsJournalTemplNameVisible: Boolean;
        SetupBlockedErr: Label 'Setup is blocked in %1 for %2 %3 and %4 %5.', Comment = '%1 - General/Inventory Posting Setup, %2 %3 %4 %5 - posting groups.';
        Text011: Label '%1 is missing for %2 %3 and %4 %5.';
        Text012: Label '%1 is missing in %2, %3 %4.';
        Text013: Label '%1 must be false, if %2 is not Direct Cost or Revaluation.';
        Text014: Label '%1 and %2 must be zero, if %3 is not Direct Cost or Revaluation.';
        Post_Inventory_Cost_to_G_L___TestCaptionLbl: Label 'Post Inventory Cost to G/L - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        DocNoCaptionLbl: Label 'Document No.';
        ItemValueEntry__Item_Ledger_Entry_No__CaptionLbl: Label 'Item Ledger Entry No.';
        TempInvtPostToGLTestBuf__Value_Entry_No__CaptionLbl: Label 'Value Entry No.';
        TempInvtPostToGLTestBuf_AmountCaptionLbl: Label 'Amount';
        TempInvtPostToGLTestBuf_DescriptionCaptionLbl: Label 'Description';
        AccNameCaptionLbl: Label 'Name';
        TempInvtPostToGLTestBuf__Account_No__CaptionLbl: Label 'Account No.';
        TempInvtPostToGLTestBuf__Document_No__CaptionLbl: Label 'Document No.';
        ItemValueEntry__Entry_Type_CaptionLbl: Label 'Value Entry Type';
        ItemValueEntry__Item_Ledger_Entry_Type_CaptionLbl: Label 'Item Ledger Entry Type';
        TempInvtPostToGLTestBuf__Posting_Date_CaptionLbl: Label 'Posting Date';
        ItemValueEntry__Item_No__CaptionLbl: Label 'Item No.';
        DimensionsCaptionLbl: Label 'Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        MissingJournalFieldErr: Label 'Please enter a %1 when posting inventory cost to G/L.', Comment = '%1 - field caption';

    local procedure FillInvtPostToGLTestBuf(ValueEntry: Record "Value Entry")
    var
        SkipFillInvtPost: Boolean;
    begin
        with ValueEntry do begin
            SkipFillInvtPost := not InvtPostToGL.BufferInvtPosting(ValueEntry);
            OnFillInvtPostToGLTestBufOnAfterCalcSkipFillInvtPost(ValueEntry, SkipFillInvtPost);
            if SkipFillInvtPost then
                exit;

            if PostMethod = PostMethod::"per Entry" then begin
                GLSetup.GetRecordOnce();
                if GLSetup."Journal Templ. Name Mandatory" then
                    InvtPostToGL.SetGenJnlBatch(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                InvtPostToGL.PostInvtPostBufPerEntry(ValueEntry);
            end;
        end;
    end;

    procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure CheckEntryCombination(ValueEntry: Record "Value Entry"): Boolean
    begin
        with ValueEntry do begin
            if not ("Entry Type" in ["Entry Type"::"Direct Cost", "Entry Type"::Revaluation]) then begin
                if "Expected Cost" then
                    AddError(
                      StrSubstNo(
                        Text013, FieldCaption("Expected Cost"), FieldCaption("Entry Type")));
                if ("Cost Amount (Expected)" <> 0) or ("Cost Amount (Expected) (ACY)" <> 0) then
                    AddError(
                      StrSubstNo(
                        Text014, FieldCaption("Cost Amount (Expected)"), FieldCaption("Cost Amount (Expected) (ACY)"),
                        FieldCaption("Entry Type")));
            end;
            case "Item Ledger Entry Type" of
                "Item Ledger Entry Type"::Sale,
              "Item Ledger Entry Type"::"Positive Adjmt.",
              "Item Ledger Entry Type"::"Negative Adjmt.",
              "Item Ledger Entry Type"::Transfer,
              "Item Ledger Entry Type"::Consumption,
              "Item Ledger Entry Type"::"Assembly Consumption":
                    if "Entry Type" in ["Entry Type"::Variance, "Entry Type"::"Indirect Cost"] then begin
                        ErrorNonValidCombination(ValueEntry);
                        exit(false);
                    end;
                "Item Ledger Entry Type"::Output,
              "Item Ledger Entry Type"::"Assembly Output":
                    if ("Entry Type" = "Entry Type"::Variance) and
                       ("Variance Type" in ["Variance Type"::" ", "Variance Type"::Purchase])
                    then begin
                        ErrorNonValidCombination(ValueEntry);
                        exit(false);
                    end;
                "Item Ledger Entry Type"::" ":
                    if not ("Entry Type" in ["Entry Type"::"Direct Cost", "Entry Type"::"Indirect Cost"]) then begin
                        ErrorNonValidCombination(ValueEntry);
                        exit(false);
                    end;
            end;
        end;
        exit(true);
    end;

    local procedure ErrorNonValidCombination(ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeErrorNonValidCombination(ValueEntry, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do
            AddError(
              StrSubstNo(
                FieldCombinationErr,
                FieldCaption("Item Ledger Entry Type"), "Item Ledger Entry Type",
                FieldCaption("Entry Type"), "Entry Type",
                FieldCaption("Expected Cost"), "Expected Cost"))
    end;

    local procedure CheckGLAcc(InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer")
    begin
        with InvtPostToGLTestBuf do
            if not GLAcc.Get("Account No.") then
                AddError(
                  StrSubstNo(DoesNotExistErr, GLAcc.TableCaption(), "Account No."))
            else begin
                AccName := GLAcc.Name;
                if GLAcc.Blocked then
                    AddError(
                      StrSubstNo(
                        MustBeForErr,
                        GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), "Account No."));
                if GLAcc."Account Type" <> GLAcc."Account Type"::Posting then begin
                    GLAcc."Account Type" := GLAcc."Account Type"::Posting;
                    AddError(
                      StrSubstNo(
                        MustBeForErr,
                        GLAcc.FieldCaption("Account Type"), GLAcc."Account Type", GLAcc.TableCaption(), "Account No."));
                end;
            end;
    end;

    local procedure CheckPostingSetup(InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingSetup(InvtPostToGLTestBuf, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with InvtPostToGLTestBuf do
            if "Invt. Posting Group Code" <> '' then begin
                if not InvtPostSetup.Get("Location Code", "Invt. Posting Group Code") then begin
                    AddError(
                      StrSubstNo(
                        Text011,
                        InvtPostSetup.TableCaption(),
                        FieldCaption("Location Code"), "Location Code",
                        FieldCaption("Invt. Posting Group Code"), "Invt. Posting Group Code"));
                    exit(false);
                end
            end else begin
                if not GenPostSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then begin
                    AddError(
                      StrSubstNo(
                        Text011,
                        GenPostSetup.TableCaption(),
                        FieldCaption("Gen. Bus. Posting Group"), "Gen. Bus. Posting Group",
                        FieldCaption("Gen. Prod. Posting Group"), "Gen. Prod. Posting Group"));
                    exit(false);
                end;
                if GenPostSetup.Blocked then begin
                    AddError(
                      StrSubstNo(
                        SetupBlockedErr,
                        GenPostSetup.TableCaption(),
                        FieldCaption("Gen. Bus. Posting Group"), "Gen. Bus. Posting Group",
                        FieldCaption("Gen. Prod. Posting Group"), "Gen. Prod. Posting Group"));
                    exit(false);
                end;
            end;
        exit(true);
    end;

    procedure GetAccountName(): Text[80]
    var
        AccountName: Text[80];
        IsHandled: Boolean;
    begin
        with TempInvtPostToGLTestBuf do
            case "Inventory Account Type" of
                "Inventory Account Type"::Inventory:
                    exit(InvtPostSetup.FieldCaption("Inventory Account"));
                "Inventory Account Type"::"Inventory (Interim)":
                    exit(InvtPostSetup.FieldCaption("Inventory Account (Interim)"));
                "Inventory Account Type"::"WIP Inventory":
                    exit(InvtPostSetup.FieldCaption("WIP Account"));
                "Inventory Account Type"::"Material Variance":
                    exit(InvtPostSetup.FieldCaption("Material Variance Account"));
                "Inventory Account Type"::"Capacity Variance":
                    exit(InvtPostSetup.FieldCaption("Capacity Variance Account"));
                "Inventory Account Type"::"Subcontracted Variance":
                    exit(InvtPostSetup.FieldCaption("Subcontracted Variance Account"));
                "Inventory Account Type"::"Cap. Overhead Variance":
                    exit(InvtPostSetup.FieldCaption("Cap. Overhead Variance Account"));
                "Inventory Account Type"::"Mfg. Overhead Variance":
                    exit(InvtPostSetup.FieldCaption("Mfg. Overhead Variance Account"));
                "Inventory Account Type"::"Inventory Adjmt.":
                    exit(GenPostSetup.FieldCaption("Inventory Adjmt. Account"));
                "Inventory Account Type"::"Direct Cost Applied":
                    exit(GenPostSetup.FieldCaption("Direct Cost Applied Account"));
                "Inventory Account Type"::"Overhead Applied":
                    exit(GenPostSetup.FieldCaption("Overhead Applied Account"));
                "Inventory Account Type"::"Purchase Variance":
                    exit(GenPostSetup.FieldCaption("Purchase Variance Account"));
                "Inventory Account Type"::COGS:
                    exit(GenPostSetup.FieldCaption("COGS Account"));
                "Inventory Account Type"::"COGS (Interim)":
                    exit(GenPostSetup.FieldCaption("COGS Account (Interim)"));
                "Inventory Account Type"::"Invt. Accrual (Interim)":
                    exit(GenPostSetup.FieldCaption("Invt. Accrual Acc. (Interim)"));
                else begin
                    IsHandled := false;
                    OnGetAccountNameInventoryAccountTypeCase(TempInvtPostToGLTestBuf, AccountName, IsHandled, InvtPostSetup, GenPostSetup);
                    if IsHandled then
                        exit(AccountName);
                end;
            end;

        OnAfterGetAccountName(TempInvtPostToGLTestBuf, InvtPostSetup, GenPostSetup, AccountName);
        exit(AccountName);
    end;

    procedure InitializeRequest(NewPostMethod: Option; NewDocNo: Code[20]; NewShowDim: Boolean; NewShowOnlyWarnings: Boolean)
    begin
        PostMethod := NewPostMethod;
        DocNo := NewDocNo;
        ShowDim := NewShowDim;
        ShowOnlyWarnings := NewShowOnlyWarnings;
    end;

    procedure SetGenJnlBatch(NewJnlTemplName: Code[10]; NewJnlBatchName: Code[10])
    begin
        GenJnlLineReq."Journal Template Name" := NewJnlTemplName;
        GenJnlLineReq."Journal Batch Name" := NewJnlBatchName;
    end;

    procedure GetParameters(var NewPostMethod: Option; var NewDocNo: Code[20]; var NewShowDim: Boolean; var NewShowOnlyWarnings: Boolean)
    begin
        NewPostMethod := PostMethod;
        NewDocNo := DocNo;
        NewShowDim := ShowDim;
        NewShowOnlyWarnings := ShowOnlyWarnings;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountName(var InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer"; InvtPostingSetup: Record "Inventory Posting Setup"; GenPostingSetup: Record "General Posting Setup"; var AccountName: Text[80])
    begin
    end;

#if not CLEAN20
    [IntegrationEvent(false, false)]
    [Obsolete('Event is never raised.', '20.0')]
    local procedure OnAfterOnPreDataItem(var PostValueEntryToGL: Record "Post Value Entry to G/L"; CompanyName: Text)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostValueEntryToGLOnPreDataItem(var PostValueEntryToGL: Record "Post Value Entry to G/L"; CompanyName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorNonValidCombination(ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport(var PostValueEntryToGL: Record "Post Value Entry to G/L"; var ItemValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillInvtPostToGLTestBufOnAfterCalcSkipFillInvtPost(var ValueEntry: Record "Value Entry"; var SkipFillInvtPost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAccountNameInventoryAccountTypeCase(InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer"; var AccountName: Text[80]; var IsHandled: Boolean; InvtPostingSetup: Record "Inventory Posting Setup"; GenPostingSetup: Record "General Posting Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPostingSetup(InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer"; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;
}

