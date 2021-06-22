page 1115 "Cost Budget Entries"
{
    Caption = 'Cost Budget Entries';
    DataCaptionFields = "Cost Type No.", "Budget Name";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Cost Budget Entry";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Budget Name"; "Budget Name")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the name of the cost budget that the entry belongs to.';
                    Visible = false;
                }
                field(Date; Date)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the date of the cost budget entry.';
                }
                field("Cost Type No."; "Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the subtype of the cost center. This is an information field and is not used for any other purposes. Choose the field to select the cost subtype.';
                }
                field("Cost Center Code"; "Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Code"; "Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount of the cost budget entries.';
                }
                field(Description; Description)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a description of the cost budget entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("System-Created Entry"; "System-Created Entry")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry created by the system for the cost budget entry.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Allocation ID"; "Allocation ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID of the allocation key that the cost budget entry comes from.';
                }
                field(Allocated; Allocated)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether the cost entry has been allocated.';
                }
                field("Allocated with Journal No."; "Allocated with Journal No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies which cost journal was used to allocate the cost budget.';
                }
                field("Allocation Description"; "Allocation Description")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the description that explains the allocation level and shares.';
                }
                field("Last Modified By User"; "Last Modified By User")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the user who made the last change to the cost budget.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        SetCostBudgetRegNo(CurrRegNo);
        Insert(true);
        CurrRegNo := GetCostBudgetRegNo;
        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Budget Name" := CostBudgetName.Name;
        if CostBudgetName.Name <> "Budget Name" then
            CostBudgetName.Get("Budget Name");
        if GetFilter("Cost Type No.") <> '' then
            "Cost Type No." := GetFirstCostType(GetFilter("Cost Type No."));
        if GetFilter("Cost Center Code") <> '' then
            "Cost Center Code" := GetFirstCostCenter(GetFilter("Cost Center Code"));
        if GetFilter("Cost Object Code") <> '' then
            "Cost Object Code" := GetFirstCostObject(GetFilter("Cost Object Code"));
        Date := GetFirstDate(GetFilter(Date));
        "Last Modified By User" := UserId;
    end;

    trigger OnOpenPage()
    begin
        if GetFilter("Budget Name") = '' then
            CostBudgetName.Init
        else begin
            CopyFilter("Budget Name", CostBudgetName.Name);
            CostBudgetName.FindFirst;
        end;
    end;

    var
        CostBudgetName: Record "Cost Budget Name";
        CurrRegNo: Integer;

    procedure SetCurrRegNo(RegNo: Integer)
    begin
        CurrRegNo := RegNo;
    end;

    procedure GetCurrRegNo(): Integer
    begin
        exit(CurrRegNo);
    end;
}

