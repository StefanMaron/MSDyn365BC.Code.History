page 1103 "Cost Entries"
{
    Caption = 'Cost Entries';
    DataCaptionFields = "Cost Type No.";
    Editable = false;
    PageType = List;
    SourceTable = "Cost Entry";

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
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
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field(Description; Description)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the description of the cost entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount of the cost entry.';
                }
                field("G/L Account"; "G/L Account")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the G/L account that the cost entry applies to.';
                }
                field("G/L Entry No."; "G/L Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry number of the corresponding general ledger entry that is associated with this cost entry. For combined entries, the entry number of the last general ledger entry is saved in the field. This is the entry with the highest entry number.';
                }
                field("Allocation ID"; "Allocation ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID of the allocation key that the cost budget entry comes from.';
                }
                field("Allocation Description"; "Allocation Description")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the description that explains the allocation level and shares.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field(Allocated; Allocated)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether the cost entry has been allocated.';
                }
                field("Additional-Currency Amount"; "Additional-Currency Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount of this entry, in the additional reporting currency.';
                    Visible = false;
                }
                field("Allocated with Journal No."; "Allocated with Journal No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies which cost journal was used to allocate the cost.';
                }
                field("System-Created Entry"; "System-Created Entry")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry created by the system for the cost entry.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Batch Name"; "Batch Name")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the journal batch name used in the posting. The name is copied from the Journal Template Name field on the cost journal line.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = CostAccounting;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
        }
    }
}

