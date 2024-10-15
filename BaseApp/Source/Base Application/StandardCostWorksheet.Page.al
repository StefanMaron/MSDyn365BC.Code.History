page 5841 "Standard Cost Worksheet"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Standard Cost Worksheet';
    DataCaptionFields = "Standard Cost Worksheet Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Standard Cost Worksheet";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrWkshName; CurrWkshName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the Standard Cost Worksheet.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    Commit;
                    if PAGE.RunModal(0, StdCostWkshName) = ACTION::LookupOK then begin
                        CurrWkshName := StdCostWkshName.Name;
                        FilterGroup := 2;
                        SetRange("Standard Cost Worksheet Name", CurrWkshName);
                        FilterGroup := 0;
                        if Find('-') then;
                    end;
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    CurrWkshNameOnAfterValidate;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of worksheet line.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the worksheet line.';
                }
                field("Standard Cost"; "Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary.';
                }
                field("New Standard Cost"; "New Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                }
                field("New Indirect Cost %"; "New Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                }
                field("Overhead Rate"; "Overhead Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the overhead rate.';
                }
                field("New Overhead Rate"; "New Overhead Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                }
                field(Implemented; Implemented)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you have run the Implement Standard Cost Changes batch job.';
                }
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the replenishment method for the items, for example, purchase or prod. order.';
                }
                field("Single-Lvl Material Cost"; "Single-Lvl Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the single-level material cost of the item.';
                    Visible = false;
                }
                field("New Single-Lvl Material Cost"; "New Single-Lvl Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Single-Lvl Cap. Cost"; "Single-Lvl Cap. Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the single-level capacity cost of the item.';
                    Visible = false;
                }
                field("New Single-Lvl Cap. Cost"; "New Single-Lvl Cap. Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Single-Lvl Subcontrd Cost"; "Single-Lvl Subcontrd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the single-level subcontracted cost of the item.';
                    Visible = false;
                }
                field("New Single-Lvl Subcontrd Cost"; "New Single-Lvl Subcontrd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Single-Lvl Cap. Ovhd Cost"; "Single-Lvl Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the single-level capacity overhead cost of the item.';
                    Visible = false;
                }
                field("New Single-Lvl Cap. Ovhd Cost"; "New Single-Lvl Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Single-Lvl Mfg. Ovhd Cost"; "Single-Lvl Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the single-level manufacturing overhead cost of the item.';
                    Visible = false;
                }
                field("New Single-Lvl Mfg. Ovhd Cost"; "New Single-Lvl Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Rolled-up Material Cost"; "Rolled-up Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the rolled-up material cost of the item.';
                    Visible = false;
                }
                field("New Rolled-up Material Cost"; "New Rolled-up Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated rolled-up material cost based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Rolled-up Cap. Cost"; "Rolled-up Cap. Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the rolled-up capacity cost of the item.';
                    Visible = false;
                }
                field("New Rolled-up Cap. Cost"; "New Rolled-up Cap. Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Rolled-up Subcontrd Cost"; "Rolled-up Subcontrd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the rolled-up subcontracted cost of the item.';
                    Visible = false;
                }
                field("New Rolled-up Subcontrd Cost"; "New Rolled-up Subcontrd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Rolled-up Cap. Ovhd Cost"; "Rolled-up Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the rolled-up capacity overhead cost of the item.';
                    Visible = false;
                }
                field("New Rolled-up Cap. Ovhd Cost"; "New Rolled-up Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
                field("Rolled-up Mfg. Ovhd Cost"; "Rolled-up Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the rolled-up manufacturing overhead cost of the item.';
                    Visible = false;
                }
                field("New Rolled-up Mfg. Ovhd Cost"; "New Rolled-up Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the updated value based on either the batch job or what you have entered manually.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest I&tem Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest I&tem Standard Cost';
                    Ellipsis = true;
                    Image = SuggestItemCost;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Creates suggestions for changing the cost shares of standard costs on Item cards. Note that the suggested changes are not implemented.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        SuggItemStdCost: Report "Suggest Item Standard Cost";
                    begin
                        Item.SetRange("Replenishment System", Item."Replenishment System"::Purchase);
                        SuggItemStdCost.SetTableView(Item);
                        SuggItemStdCost.SetCopyToWksh(CurrWkshName);
                        SuggItemStdCost.RunModal;
                    end;
                }
                action("Suggest &Capacity Standard Cost")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Suggest &Capacity Standard Cost';
                    Ellipsis = true;
                    Image = SuggestCapacity;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create suggestions on new worksheet lines for changing the costs and cost shares of standard costs on work center, machine center, or resource cards.';

                    trigger OnAction()
                    var
                        SuggWorkMachCtrStdWksh: Report "Suggest Capacity Standard Cost";
                    begin
                        SuggWorkMachCtrStdWksh.SetCopyToWksh(CurrWkshName);
                        SuggWorkMachCtrStdWksh.RunModal;
                    end;
                }
                action("Copy Standard Cost Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Standard Cost Worksheet';
                    Ellipsis = true;
                    Image = CopyWorksheet;
                    ToolTip = 'Copies standard cost worksheets from several sources into the Standard Cost Worksheet window.';

                    trigger OnAction()
                    var
                        CopyStdCostWksh: Report "Copy Standard Cost Worksheet";
                    begin
                        CopyStdCostWksh.SetCopyToWksh(CurrWkshName);
                        CopyStdCostWksh.RunModal;
                    end;
                }
                action("Roll Up Standard Cost")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Roll Up Standard Cost';
                    Ellipsis = true;
                    Image = RollUpCosts;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Roll up the standard costs of assembled and manufactured items, for example, with changes in the standard cost of components and changes in the standard cost of production capacity and assembly resources. When you run the function, all changes to the standard costs in the worksheet are introduced in the associated production or assembly BOMs, and the costs are applied at each BOM level.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        RollUpStdCost: Report "Roll Up Standard Cost";
                    begin
                        Clear(RollUpStdCost);
                        Item.SetRange("Costing Method", Item."Costing Method"::Standard);
                        RollUpStdCost.SetTableView(Item);
                        RollUpStdCost.SetStdCostWksh(CurrWkshName);
                        RollUpStdCost.RunModal;
                    end;
                }
                action("&Implement Standard Cost Changes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Implement Standard Cost Changes';
                    Ellipsis = true;
                    Image = ImplementCostChanges;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Updates the changes in the standard cost in the Item table with the ones in the Standard Cost Worksheet table.';

                    trigger OnAction()
                    var
                        ImplStdCostChg: Report "Implement Standard Cost Change";
                    begin
                        Clear(ImplStdCostChg);
                        ImplStdCostChg.SetStdCostWksh(CurrWkshName);
                        ImplStdCostChg.RunModal;
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        StdCostWkshName.Get("Standard Cost Worksheet Name");
        Type := xRec.Type;
        "Replenishment System" := "Replenishment System"::Assembly;
    end;

    trigger OnOpenPage()
    begin
        if "Standard Cost Worksheet Name" <> '' then // called from batch
            CurrWkshName := "Standard Cost Worksheet Name";

        if not StdCostWkshName.Get(CurrWkshName) then
            if not StdCostWkshName.FindFirst then begin
                StdCostWkshName.Name := DefaultNameTxt;
                StdCostWkshName.Description := DefaultNameTxt;
                StdCostWkshName.Insert;
            end;
        CurrWkshName := StdCostWkshName.Name;

        FilterGroup := 2;
        SetRange("Standard Cost Worksheet Name", CurrWkshName);
        FilterGroup := 0;
    end;

    var
        StdCostWkshName: Record "Standard Cost Worksheet Name";
        CurrWkshName: Code[10];
        DefaultNameTxt: Label 'Default';

    local procedure CurrWkshNameOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        Commit;
        FilterGroup := 2;
        SetRange("Standard Cost Worksheet Name", CurrWkshName);
        FilterGroup := 0;
        if Find('-') then;
        CurrPage.Update(false);
    end;
}

