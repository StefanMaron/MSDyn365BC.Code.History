report 795 "Adjust Cost - Item Entries"
{
    AdditionalSearchTerms = 'cost forwarding';
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Cost - Item Entries';
    Permissions = TableData "Item Ledger Entry" = rimd,
                  TableData "Item Application Entry" = r,
                  TableData "Value Entry" = rimd,
                  TableData "Avg. Cost Adjmt. Entry Point" = rimd;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
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
                    field(FilterItemNo; ItemNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item No. Filter';
                        Editable = FilterItemNoEditable;
                        ToolTip = 'Specifies a filter to run the Adjust Cost - Item Entries batch job for only certain items. You can leave this field blank to run the batch job for all items.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ItemList: Page "Item List";
                        begin
                            ItemList.LookupMode := true;
                            if ItemList.RunModal() = ACTION::LookupOK then
                                Text := ItemList.GetSelectionFilter()
                            else
                                exit(false);

                            exit(true);
                        end;
                    }
                    field(FilterItemCategory; ItemCategoryFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Category Filter';
                        Editable = FilterItemCategoryEditable;
                        TableRelation = "Item Category";
                        ToolTip = 'Specifies a filter to run the Adjust Cost - Item Entries batch job for only certain item categories. You can leave this field blank to run the batch job for all item categories.';
                    }
                    field(Post; PostToGL)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post to G/L';
                        Enabled = PostEnable;
                        ToolTip = 'Specifies that inventory values created during the Adjust Cost - Item Entries batch job are posted to the inventory accounts in the general ledger. The option is only available if the Automatic Cost Posting check box is selected in the Inventory Setup window.';

                        trigger OnValidate()
                        var
                            ObjTransl: Record "Object Translation";
                        begin
                            if not PostToGL then
                                Message(
                                  ResynchronizeInfoMsg,
                                  ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, REPORT::"Post Inventory Cost to G/L"));
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        var
            ClientTypeManagement: Codeunit "Client Type Management";
        begin
            FilterItemCategoryEditable := true;
            FilterItemNoEditable := true;
            PostEnable := true;
            if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then begin
                InvtSetup.Get();
                PostToGL := InvtSetup."Automatic Cost Posting";
            end;
        end;

        trigger OnOpenPage()
        begin
            InvtSetup.Get();
            PostToGL := InvtSetup."Automatic Cost Posting";
            PostEnable := PostToGL;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemApplnEntry: Record "Item Application Entry";
        Item: Record Item;
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        OnBeforePreReport(ItemNoFilter, ItemCategoryFilter, PostToGL, Item);

        ItemApplnEntry.LockTable();
        if not ItemApplnEntry.FindLast() then
            exit;
        ItemLedgEntry.LockTable();
        if not ItemLedgEntry.FindLast() then
            exit;

        AvgCostEntryPointHandler.LockBuffer();

        ValueEntry.LockTable();
        if not ValueEntry.FindLast() then
            exit;

        if (ItemNoFilter <> '') and (ItemCategoryFilter <> '') then
            Error(Text005);

        if ItemNoFilter <> '' then
            Item.SetFilter("No.", ItemNoFilter);
        if ItemCategoryFilter <> '' then
            Item.SetFilter("Item Category Code", ItemCategoryFilter);

        InvtAdjmtHandler.SetFilterItem(Item);
        InvtAdjmtHandler.MakeInventoryAdjustment(false, PostToGL);

        if PostToGL then
            UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);

        OnAfterPreReport();
    end;

    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        [InDataSet]
        PostEnable: Boolean;
        [InDataSet]
        FilterItemNoEditable: Boolean;
        [InDataSet]
        FilterItemCategoryEditable: Boolean;

        Text005: Label 'You must not use Item No. Filter and Item Category Filter at the same time.';
        ResynchronizeInfoMsg: Label 'Your general and item ledgers will no longer be synchronized after running the cost adjustment. You must run the %1 report to synchronize them again.';

    protected var
        ItemNoFilter: Text[250];
        ItemCategoryFilter: Text[250];
        PostToGL: Boolean;

    procedure InitializeRequest(NewItemNoFilter: Text[250]; NewItemCategoryFilter: Text[250])
    begin
        ItemNoFilter := NewItemNoFilter;
        ItemCategoryFilter := NewItemCategoryFilter;
    end;

    procedure SetPostToGL(NewPostToGL: Boolean)
    begin
        PostToGL := NewPostToGL;
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterPreReport()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePreReport(ItemNoFilter: Text[250]; ItemCategoryFilter: Text[250]; PostToGL: Boolean; var Item: Record Item)
    begin
    end;
}

