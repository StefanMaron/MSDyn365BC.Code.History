report 1002 "Post Inventory Cost to G/L"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PostInventoryCosttoGL.rdlc';
    AdditionalSearchTerms = 'reconcile inventory';
    ApplicationArea = Basic, Suite;
    Caption = 'Post Inventory Cost to G/L';
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Invt. Posting Buffer" = r,
                  TableData "Prod. Order Line" = r,
                  TableData "Value Entry" = rm,
                  TableData "Post Value Entry to G/L" = rd,
                  TableData "Capacity Ledger Entry" = rm;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PageLoop; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(PostedCaption; StrSubstNo(Text002, SelectStr(PostMethod + 1, Text012)))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(Post; Post)
            {
            }
            column(DocNo; DocNo)
            {
            }
            column(PostMethodInt; PostMethodInt)
            {
            }
            column(ItemValueEntryTableCaption; ItemValueEntry.TableCaption + ': ' + ValueEntryFilter)
            {
            }
            column(ValueEntryFilter; ValueEntryFilter)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(PostInvCosttoGLCaption; PostInvCosttoGLCaptionLbl)
            {
            }
            column(TestReportnotpostedCaption; TestReportnotpostedCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            dataitem(PerEntryLoop; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                PrintOnlyIfDetail = true;
                column(PerEntryLoopNumber; Number)
                {
                }
                column(TotalCOGSAmt; TotalCOGSAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalInvtAdjmtAmt; TotalInvtAdjmtAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalDirCostAmt; TotalDirCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalOvhdCostAmt; TotalOvhdCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalVarPurchCostAmt; TotalVarPurchCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalVarMfgDirCostAmt; TotalVarMfgDirCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalVarMfgOvhdCostAmt; TotalVarMfgOvhdCostAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalWIPInvtAmt; TotalWIPInvtAmt)
                {
                    AutoFormatType = 1;
                }
                column(TotalInvtAmt; TotalInvtAmt)
                {
                    AutoFormatType = 1;
                }
                column(EntryNoCaption; EntryNoCaptionLbl)
                {
                }
                column(ItemLedgerEntryTypeCaption; ItemLedgerEntryTypeCaptionLbl)
                {
                }
                column(SourceNoCaption; SourceNoCaptionLbl)
                {
                }
                column(InvPostingGroupCaption; InvPostingGroupCaptionLbl)
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(COGSCaption; COGSCaptionLbl)
                {
                }
                column(InventoryAdjustmentCaption; InventoryAdjustmentCaptionLbl)
                {
                }
                column(DirectCostAppliedCaption; DirectCostAppliedCaptionLbl)
                {
                }
                column(OverheadAppliedCaption; OverheadAppliedCaptionLbl)
                {
                }
                column(PurchaseVarianceCaption; PurchaseVarianceCaptionLbl)
                {
                }
                column(VarMfgDirectCostAppliedCaption; VarMfgDirectCostAppliedCaptionLbl)
                {
                }
                column(MfgOvhdVarianceCaption; MfgOvhdVarianceCaptionLbl)
                {
                }
                column(WIPInventoryCaption; WIPInventoryCaptionLbl)
                {
                }
                column(InventoryCaption; InventoryCaptionLbl)
                {
                }
                column(ExpectedCostCaption; ExpectedCostCaptionLbl)
                {
                }
                column(InventoryCostPostedtoGLCaption; InventoryCostPostedtoGLCaptionLbl)
                {
                }
                dataitem(PostValueEntryToGL; "Post Value Entry to G/L")
                {
                    DataItemTableView = SORTING("Item No.", "Posting Date");
                    RequestFilterFields = "Item No.", "Posting Date";
                    column(ItemDescription; Item.Description)
                    {
                    }
                    column(ItemNo_PostValueEntryToGL; "Item No.")
                    {
                    }
                    column(ItemValueEntryPostingDate; Format(ItemValueEntry."Posting Date"))
                    {
                    }
                    column(ItemValueEntryInvPostingGroup; ItemValueEntry."Inventory Posting Group")
                    {
                    }
                    column(ItemValueEntryDocumentNo; ItemValueEntry."Document No.")
                    {
                    }
                    column(ItemValueEntryItemLedgerEntryType; Format(ItemValueEntry."Item Ledger Entry Type"))
                    {
                    }
                    column(ItemValueEntryEntryNo; ItemValueEntry."Entry No.")
                    {
                    }
                    column(ItemValueEntrySourceNo; ItemValueEntry."Source No.")
                    {
                    }
                    column(ItemValueEntryExpectedCost; Format(ItemValueEntry."Expected Cost"))
                    {
                    }
                    column(InvtAmt; InvtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(WIPInvtAmt; WIPInvtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarMfgOvhdAmt; VarMfgOvhdAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarMfgDirCostAmt; VarMfgDirCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarPurchCostAmt; VarPurchCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(OvhdCostAmt; OvhdCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(DirCostAmt; DirCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(InvtAdjmtAmt; InvtAdjmtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(COGSAmt; COGSAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(ItemCaption; ItemCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ItemValueEntry.Get("Value Entry No.");
                        with ItemValueEntry do begin
                            if "Item Ledger Entry No." = 0 then begin
                                TempCapValueEntry."Entry No." := "Entry No.";
                                TempCapValueEntry."Order Type" := "Order Type";
                                TempCapValueEntry."Order No." := "Order No.";
                                TempCapValueEntry.Insert;
                            end;

                            if ("Item Ledger Entry No." = 0) or not Inventoriable or
                               (("Cost Amount (Actual)" = 0) and ("Cost Amount (Expected)" = 0) and
                                ("Cost Amount (Actual) (ACY)" = 0) and ("Cost Amount (Expected) (ACY)" = 0))
                            then
                                CurrReport.Skip;
                        end;

                        if not InvtPost.BufferInvtPosting(ItemValueEntry) then begin
                            InsertValueEntryNoBuf(ItemValueEntry);
                            CurrReport.Skip;
                        end;

                        UpdateAmounts;
                        Mark(true);
                        if Post and (PostMethod = PostMethod::"per Entry") then
                            PostEntryToGL(ItemValueEntry);

                        if GuiAllowed then
                            Window.Update(1, "Item No.");
                        if not Item.Get("Item No.") then
                            Item.Description := Text005;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if Post then begin
                            MarkedOnly(true);
                            DeleteAll;
                        end;
                        Window.Close;
                    end;

                    trigger OnPreDataItem()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        Window.Open(Text003);
                        if Post then begin
                            GLEntry.LockTable;
                            if GLEntry.FindLast then;
                        end;

                        OnAfterOnPreDataItem(PostValueEntryToGL, CompanyName());
                    end;
                }
                dataitem(CapValueEntryLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(OrderNo_CapValueEntryProd; CapValueEntry."Order No.")
                    {
                        IncludeCaption = true;
                    }
                    column(ExpectedCost_CapValueEntry; Format(CapValueEntry."Expected Cost"))
                    {
                    }
                    column(InvtAmt2; InvtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(WIPInvtAmt2; WIPInvtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarMfgOvhdAmt2; VarMfgOvhdAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarMfgDirCostAmt2; VarMfgDirCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(VarPurchCostAmt2; VarPurchCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(OvhdCostAmt2; OvhdCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(DirCostAmt2; DirCostAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(InvtAdjmtAmt2; InvtAdjmtAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(COGSAmt2; COGSAmt)
                    {
                        AutoFormatType = 1;
                    }
                    column(PostingDate_CapValueEntry; Format(CapValueEntry."Posting Date"))
                    {
                    }
                    column(InvPostingGroup_CapValueEntry; CapValueEntry."Inventory Posting Group")
                    {
                    }
                    column(SourceNo_CapValueEntry; CapValueEntry."Source No.")
                    {
                    }
                    column(DocumentNo_CapValueEntry; CapValueEntry."Document No.")
                    {
                    }
                    column(ItemLedgEntryType_CapValueEntry; CapValueEntry."Item Ledger Entry Type")
                    {
                    }
                    column(EntryNo_CapValueEntry; CapValueEntry."Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CapValueEntry.Get(TempCapValueEntry."Entry No.");
                        if TempCapValueEntry.Next = 0 then;
                        if not InvtPost.BufferInvtPosting(CapValueEntry) then begin
                            InsertValueEntryNoBuf(CapValueEntry);
                            CurrReport.Skip;
                        end;

                        UpdateAmounts;
                        PostValueEntryToGL.Get(CapValueEntry."Entry No.");
                        PostValueEntryToGL.Mark(true);
                        if Post and (PostMethod = PostMethod::"per Entry") then
                            PostEntryToGL(CapValueEntry);

                        if GuiAllowed and (PrevCapValueEntryOrderNo <> CapValueEntry."Order No.") then begin
                            Window.Update(1, CapValueEntry."Order No.");
                            PrevCapValueEntryOrderNo := CapValueEntry."Order No.";
                        end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempCapValueEntry.DeleteAll;
                        if Post then begin
                            PostValueEntryToGL.MarkedOnly(true);
                            PostValueEntryToGL.DeleteAll;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempCapValueEntry.Count);

                        TempCapValueEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
                        if TempCapValueEntry.FindSet and GuiAllowed then
                            Window.Open(Text99000000);
                    end;
                }

                trigger OnPreDataItem()
                begin
                    case PostMethod of
                        PostMethod::"per Posting Group":
                            if DocNo = '' then
                                Error(
                                  Text000, ItemValueEntry.FieldCaption("Document No."), SelectStr(PostMethod + 1, Text012));
                        PostMethod::"per Entry":
                            if DocNo <> '' then
                                Error(
                                  Text001, ItemValueEntry.FieldCaption("Document No."), SelectStr(PostMethod + 1, Text012));
                    end;
                    GLSetup.Get;
                end;
            }
            dataitem(InvtPostingBufferLoop; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(InvtPostBufAccTypeFormatted; Format(InvtPostBuf."Account Type"))
                {
                }
                column(DimText; DimText)
                {
                }
                column(GenPostingSetupTxt; GenPostingSetupTxt)
                {
                }
                column(InvtPostBufAmount; InvtPostBuf.Amount)
                {
                }
                column(InvtPostBufPostingDate; Format(InvtPostBuf."Posting Date"))
                {
                }
                column(EntryTypeCaption; EntryTypeCaptionLbl)
                {
                }
                column(DimTextCaption; DimTextCaptionLbl)
                {
                }
                column(GenPostingSetupTxtCaption; GenPostingSetupTxtCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(InvtPostBufAmountCaption; InvtPostBufAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    DimSetEntry: Record "Dimension Set Entry";
                begin
                    if Number = 1 then begin
                        if not InvtPostBuf.FindSet then
                            CurrReport.Break;
                    end else
                        if InvtPostBuf.Next = 0 then
                            CurrReport.Break;

                    DimSetEntry.SetRange("Dimension Set ID", InvtPostBuf."Dimension Set ID");
                    GetDimText(DimSetEntry);

                    if InvtPostBuf.UseInvtPostSetup then
                        GenPostingSetupTxt :=
                          StrSubstNo('%1,%2', InvtPostBuf."Location Code", InvtPostBuf."Inventory Posting Group")
                    else
                        GenPostingSetupTxt :=
                          StrSubstNo('%1,%2', InvtPostBuf."Gen. Bus. Posting Group", InvtPostBuf."Gen. Prod. Posting Group");
                end;

                trigger OnPostDataItem()
                var
                    ValueEntry: Record "Value Entry";
                begin
                    if Post and (PostMethod = PostMethod::"per Posting Group") then begin
                        ValueEntry."Document No." := DocNo;
                        PostEntryToGL(ValueEntry);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if PostMethod = PostMethod::"per Posting Group" then
                        InvtPost.GetInvtPostBuf(InvtPostBuf);
                    InvtPostBuf.Reset;
                end;
            }
            dataitem(SkippedValueEntry; "Value Entry")
            {
                DataItemTableView = SORTING("Item No.");
                column(ItemNo_SkippedValueEntry; "Item No.")
                {
                }
                column(CostAmt; CostAmt)
                {
                }
                column(ExpectedCost_SkippedValueEntry; Format("Expected Cost"))
                {
                }
                column(GenProdPostingGroup_SkippedValueEntry; "Gen. Prod. Posting Group")
                {
                    IncludeCaption = true;
                }
                column(GenBusPostingGroup_SkippedValueEntry; "Gen. Bus. Posting Group")
                {
                    IncludeCaption = true;
                }
                column(LocationCode_SkippedValueEntry; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(InventoryPostingGroup_SkippedValueEntry; "Inventory Posting Group")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_SkippedValueEntry; Format("Posting Date"))
                {
                }
                column(SourceNo_SkippedValueEntry; "Source No.")
                {
                    IncludeCaption = true;
                }
                column(DocumentNo_SkippedValueEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(EntryType_SkippedValueEntry; "Entry Type")
                {
                    IncludeCaption = true;
                }
                column(ItemLedgEntryType_SkippedValueEntry; "Item Ledger Entry Type")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_SkippedValueEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(CostAmtCaption; CostAmtCaptionLbl)
                {
                }
                column(ExpectedCost_SkippedValueEntryCaption; ExpectedCost_SkippedValueEntryCaptionLbl)
                {
                }
                column(SkippedItemsCaption; SkippedItemsCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if TempValueEntry.Next = 0 then
                        Clear(TempValueEntry);

                    SetRange("Item No.", TempValueEntry."Item No.");
                    SetRange("Entry No.", TempValueEntry."Entry No.");

                    if Item.Get("Item No.") then;
                    if "Expected Cost" then
                        CostAmt := "Cost Amount (Expected)"
                    else
                        CostAmt := "Cost Amount (Actual)";
                end;

                trigger OnPreDataItem()
                begin
                    TempValueEntry.SetCurrentKey("Item No.");
                    if not TempValueEntry.FindSet then
                        CurrReport.Break;

                    SetRange("Item No.", TempValueEntry."Item No.");
                    SetRange("Entry No.", TempValueEntry."Entry No.");
                end;
            }

            trigger OnPreDataItem()
            begin
                PostMethodInt := PostMethod;
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
                    field(PostMethod; PostMethod)
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
                    field(Post; Post)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies that the costs will be posted when you run the batch job.';
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

    trigger OnInitReport()
    begin
        TotalValueEntriesPostedToGL := 0;
    end;

    trigger OnPostReport()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        if Post then
            UpdateAnalysisView.UpdateAll(0, true);
        DisplayStatistics(Post);
    end;

    trigger OnPreReport()
    begin
        OnBeforePreReport(Item, ItemValueEntry, PostValueEntryToGL);

        ValueEntryFilter := PostValueEntryToGL.GetFilters;
        InvtSetup.Get;
    end;

    var
        Text000: Label 'Please enter a %1 when posting %2.';
        Text001: Label 'Do not enter a %1 when posting %2.';
        Text002: Label 'Posted %1';
        Text003: Label 'Processing items  #1##########';
        Text005: Label 'The item no. no longer exists.';
        Text99000000: Label 'Processing production order  #1##########';
        Item: Record Item;
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        InvtPostBuf: Record "Invt. Posting Buffer" temporary;
        TempCapValueEntry: Record "Value Entry" temporary;
        TempValueEntry: Record "Value Entry" temporary;
        ItemValueEntry: Record "Value Entry";
        CapValueEntry: Record "Value Entry";
        InvtPost: Codeunit "Inventory Posting To G/L";
        Window: Dialog;
        DocNo: Code[20];
        GenPostingSetupTxt: Text[250];
        ValueEntryFilter: Text;
        DimText: Text[120];
        PostMethod: Option "per Posting Group","per Entry";
        COGSAmt: Decimal;
        InvtAdjmtAmt: Decimal;
        DirCostAmt: Decimal;
        OvhdCostAmt: Decimal;
        VarPurchCostAmt: Decimal;
        VarMfgDirCostAmt: Decimal;
        VarMfgOvhdAmt: Decimal;
        WIPInvtAmt: Decimal;
        InvtAmt: Decimal;
        TotalCOGSAmt: Decimal;
        TotalInvtAdjmtAmt: Decimal;
        TotalDirCostAmt: Decimal;
        TotalOvhdCostAmt: Decimal;
        TotalVarPurchCostAmt: Decimal;
        TotalVarMfgDirCostAmt: Decimal;
        TotalVarMfgOvhdCostAmt: Decimal;
        TotalWIPInvtAmt: Decimal;
        TotalInvtAmt: Decimal;
        CostAmt: Decimal;
        Post: Boolean;
        Text012: Label 'per Posting Group,per Entry';
        PostMethodInt: Integer;
        PageNoCaptionLbl: Label 'Page';
        PostInvCosttoGLCaptionLbl: Label 'Post Inventory Cost to G/L';
        TestReportnotpostedCaptionLbl: Label 'Test Report (Not Posted)';
        DocNoCaptionLbl: Label 'Document No.';
        EntryNoCaptionLbl: Label 'Entry No.';
        ItemLedgerEntryTypeCaptionLbl: Label 'Item Ledger Entry Type';
        SourceNoCaptionLbl: Label 'Source No.';
        InvPostingGroupCaptionLbl: Label 'Inventory Posting Group';
        PostingDateCaptionLbl: Label 'Posting Date';
        COGSCaptionLbl: Label 'COGS', Comment = 'Cost of goods sold';
        InventoryAdjustmentCaptionLbl: Label 'Inventory Adjustment';
        DirectCostAppliedCaptionLbl: Label 'Direct Cost Applied';
        OverheadAppliedCaptionLbl: Label 'Overhead Applied';
        PurchaseVarianceCaptionLbl: Label 'Purchase Variance';
        VarMfgDirectCostAppliedCaptionLbl: Label 'Mfg. Direct Cost Variance';
        MfgOvhdVarianceCaptionLbl: Label 'Manufacturing Ovhd Variance';
        WIPInventoryCaptionLbl: Label 'WIP Inventory';
        InventoryCaptionLbl: Label 'Inventory';
        ExpectedCostCaptionLbl: Label 'Expected Cost';
        InventoryCostPostedtoGLCaptionLbl: Label 'Inventory Cost Posted to G/L';
        ItemCaptionLbl: Label 'Item';
        EntryTypeCaptionLbl: Label 'Entry Type';
        DimTextCaptionLbl: Label 'Line Dimensions';
        GenPostingSetupTxtCaptionLbl: Label 'General Posting Setup';
        TotalCaptionLbl: Label 'Total';
        InvtPostBufAmountCaptionLbl: Label 'Amount';
        CostAmtCaptionLbl: Label 'Cost Amount';
        ExpectedCost_SkippedValueEntryCaptionLbl: Label 'Skipped Value Entries';
        SkippedItemsCaptionLbl: Label 'Skipped Items';
        PrevCapValueEntryOrderNo: Code[20];
        TotalValueEntriesPostedToGL: Integer;
        StatisticsMsg: Label '%1 value entries have been posted to the general ledger.', Comment = '10 value entries have been posted to the general ledger.';
        NothingToPostMsg: Label 'There is nothing to post to the general ledger.';

    procedure InitializeRequest(NewPostMethod: Option; NewDocNo: Code[20]; NewPost: Boolean)
    begin
        PostMethod := NewPostMethod;
        DocNo := NewDocNo;
        Post := NewPost;
    end;

    local procedure GetDimText(var DimSetEntry: Record "Dimension Set Entry")
    var
        OldDimText: Text[75];
    begin
        DimText := '';

        if DimSetEntry.FindSet then
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
                    exit;
                end;
            until DimSetEntry.Next = 0;
    end;

    local procedure PostEntryToGL(ValueEntry: Record "Value Entry")
    begin
        InvtPost.Initialize(PostMethod = PostMethod::"per Posting Group");
        InvtPost.Run(ValueEntry);
        TotalValueEntriesPostedToGL += 1;
    end;

    local procedure UpdateAmounts()
    begin
        InvtPost.GetAmtToPost(
          COGSAmt, InvtAdjmtAmt, DirCostAmt,
          OvhdCostAmt, VarPurchCostAmt, VarMfgDirCostAmt, VarMfgOvhdAmt,
          WIPInvtAmt, InvtAmt, false);

        InvtPost.GetAmtToPost(
          TotalCOGSAmt, TotalInvtAdjmtAmt, TotalDirCostAmt,
          TotalOvhdCostAmt, TotalVarPurchCostAmt, TotalVarMfgDirCostAmt, TotalVarMfgOvhdCostAmt,
          TotalWIPInvtAmt, TotalInvtAmt, true);
    end;

    local procedure InsertValueEntryNoBuf(ValueEntry: Record "Value Entry")
    begin
        TempValueEntry.Init;
        TempValueEntry := ValueEntry;
        TempValueEntry.Insert;
    end;

    local procedure DisplayStatistics(NotSimulation: Boolean)
    begin
        if GuiAllowed and NotSimulation then
            if TotalValueEntriesPostedToGL > 0 then
                Message(StatisticsMsg, TotalValueEntriesPostedToGL)
            else
                Message(NothingToPostMsg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItem(var PostValueEntryToGL: Record "Post Value Entry to G/L"; CompanyName: Text)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePreReport(var Item: Record Item; var ItemValueEntry: Record "Value Entry"; var PostValueEntryToGL: Record "Post Value Entry to G/L")
    begin
    end;
}

