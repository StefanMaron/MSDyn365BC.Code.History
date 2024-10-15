page 35491 "Subcontracting Transfer List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Subcontracting Transfer Orders';
    CardPageID = "Subcontr. Transfer Order";
    Editable = false;
    PageType = List;
    SourceTable = "Transfer Header";
    SourceTableView = SORTING("No.")
                      WHERE("Subcontracting Order" = CONST(true));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the document number.';
                }
                field("Transfer-from Code"; "Transfer-from Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code of the location that you are transferring items from.';
                }
                field("Transfer-to Code"; "Transfer-to Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code of the location that you are transferring items to.';
                }
                field("In-Transit Code"; "In-Transit Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the transfer route for transferring items between locations.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        DimMgt.LookupDimValueCodeNoUpdate(1);
                    end;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        DimMgt.LookupDimValueCodeNoUpdate(2);
                    end;
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the user that the document is assigned to.';
                }
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
                action("Re&lease")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document.';

                    trigger OnAction()
                    var
                        TransHeader: Record "Transfer Header";
                        ReleaseTransferDoc: Codeunit "Release Transfer Document";
                    begin
                        CurrPage.SetSelectionFilter(TransHeader);
                        if TransHeader.Find('-') then
                            repeat
                                ReleaseTransferDoc.Run(TransHeader);
                            until TransHeader.Next() = 0;
                    end;
                }
            }
        }
    }

    var
        DimMgt: Codeunit DimensionManagement;
}

