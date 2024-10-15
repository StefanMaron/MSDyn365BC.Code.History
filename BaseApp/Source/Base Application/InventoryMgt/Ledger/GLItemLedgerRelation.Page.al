namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Navigate;

page 5823 "G/L - Item Ledger Relation"
{
    Caption = 'G/L - Item Ledger Relation';
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = "G/L - Item Ledger Relation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("ValueEntry.""Posting Date"""; ValueEntry."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date that represents the relation.';
                }
                field("ValueEntry.""Item No."""; ValueEntry."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item number that represents the relation.';
                }
                field("FORMAT(ValueEntry.""Source Type"")"; Format(ValueEntry."Source Type"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Type';
                    ToolTip = 'Specifies the source type that represents the relation.';
                }
                field("ValueEntry.""Source No."""; ValueEntry."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source No.';
                    ToolTip = 'Specifies the source number that represents the relation.';
                }
                field("ValueEntry.""External Document No."""; ValueEntry."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Document No.';
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("FORMAT(ValueEntry.""Document Type"")"; Format(ValueEntry."Document Type"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the type of document.';
                    Visible = false;
                }
                field("ValueEntry.""Document No."""; ValueEntry."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document that represents the relation.';
                }
                field("ValueEntry.""Document Line No."""; ValueEntry."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Line No.';
                    ToolTip = 'Specifies the document line number.';
                    Visible = false;
                }
                field("ValueEntry.Description"; ValueEntry.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the document that represents the relation.';
                }
                field("ValueEntry.""Location Code"""; ValueEntry."Location Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Location Code';
                    ToolTip = 'Specifies the location of the item.';
                }
                field("ValueEntry.""Inventory Posting Group"""; ValueEntry."Inventory Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Posting Group';
                    ToolTip = 'Specifies the inventory posting group that represents the relation.';
                }
                field("ValueEntry.""Gen. Bus. Posting Group"""; ValueEntry."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gen. Bus. Posting Group';
                    ToolTip = 'Specifies the general business posting group that represents the relation.';
                }
                field("ValueEntry.""Gen. Prod. Posting Group"""; ValueEntry."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gen. Prod. Posting Group';
                    ToolTip = 'Specifies the general product posting group that represents the relation.';
                }
                field("ValueEntry.""Source Posting Group"""; ValueEntry."Source Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Posting Group';
                    ToolTip = 'Specifies the source posting group that represents the relation.';
                }
                field("FORMAT(ValueEntry.""Item Ledger Entry Type"")"; Format(ValueEntry."Item Ledger Entry Type"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Ledger Entry Type';
                    ToolTip = 'Specifies the item ledger entry type that represents the relation.';
                }
                field("ValueEntry.""Item Ledger Entry No."""; ValueEntry."Item Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Ledger Entry No.';
                    ToolTip = 'Specifies the item ledger entry number that represents the relation.';
                }
                field("ValueEntry.""Valued Quantity"""; ValueEntry."Valued Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Valued Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the valued quantity that represents the relation.';
                }
                field("ValueEntry.""Item Ledger Entry Quantity"""; ValueEntry."Item Ledger Entry Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Ledger Entry Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item ledger entry quantity that represents the relation.';
                }
                field("ValueEntry.""Invoiced Quantity"""; ValueEntry."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoiced Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the invoiced quantity that represents the relation.';
                }
                field("ValueEntry.""Cost per Unit"""; ValueEntry."Cost per Unit")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cost per Unit';
                    ToolTip = 'Specifies the cost per unit that represents the relation.';
                }
                field("ValueEntry.""User ID"""; ValueEntry."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the user who created the item ledger entry.';
                    Visible = false;
                }
                field("ValueEntry.""Source Code"""; ValueEntry."Source Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Source Code';
                    ToolTip = 'Specifies the source.';
                    Visible = false;
                }
                field("ValueEntry.""Cost Amount (Actual)"""; ValueEntry."Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Amount (Actual)';
                    ToolTip = 'Specifies the sum of the actual cost amounts posted for the item ledger entries';
                }
                field("ValueEntry.""Cost Posted to G/L"""; ValueEntry."Cost Posted to G/L")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Posted to G/L';
                    ToolTip = 'Specifies the amount that has been posted to the general ledger.';
                }
                field("ValueEntry.""Cost Amount (Actual) (ACY)"""; ValueEntry."Cost Amount (Actual) (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Amount (Actual) (ACY)';
                    ToolTip = 'Specifies the actual cost amount of the item.';
                    Visible = false;
                }
                field("ValueEntry.""Cost Posted to G/L (ACY)"""; ValueEntry."Cost Posted to G/L (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Posted to G/L (ACY)';
                    ToolTip = 'Specifies the amount that has been posted to the general ledger shown in the additional reporting currency.';
                }
                field("ValueEntry.""Cost per Unit (ACY)"""; ValueEntry."Cost per Unit (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 2;
                    Caption = 'Cost per Unit (ACY)';
                    ToolTip = 'Specifies the cost per unit for the ledger entry.';
                    Visible = false;
                }
                field("ValueEntry.""Global Dimension 1 Code"""; ValueEntry."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,1,1';
                    Caption = 'Global Dimension 1 Code';
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("ValueEntry.""Global Dimension 2 Code"""; ValueEntry."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,1,2';
                    Caption = 'Global Dimension 2 Code';
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("ValueEntry.""Expected Cost"""; ValueEntry."Expected Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expected Cost';
                    ToolTip = 'Specifies the estimation of a purchased item''s cost that you record before you receive the invoice for the item.';
                    Visible = false;
                }
                field("ValueEntry.""Item Charge No."""; ValueEntry."Item Charge No.")
                {
                    ApplicationArea = ItemCharges;
                    Caption = 'Item Charge No.';
                    ToolTip = 'Specifies the number of the related item charge.';
                    Visible = false;
                }
                field("FORMAT(ValueEntry.""Entry Type"")"; Format(ValueEntry."Entry Type"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Type';
                    ToolTip = 'Specifies the entry type that represents the relation.';
                }
                field("FORMAT(ValueEntry.""Variance Type"")"; Format(ValueEntry."Variance Type"))
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Variance Type';
                    ToolTip = 'Specifies the type of variance, if any.';
                    Visible = false;
                }
                field("ValueEntry.""Cost Amount (Expected)"""; ValueEntry."Cost Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Amount (Expected)';
                    ToolTip = 'Specifies the expected cost amount of the item. Expected costs are calculated from yet non-invoiced documents.';
                    Visible = false;
                }
                field("ValueEntry.""Cost Amount (Expected) (ACY)"""; ValueEntry."Cost Amount (Expected) (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Amount (Expected) (ACY)';
                    ToolTip = 'Specifies the expected cost amount of the item. Expected costs are calculated from yet non-invoiced documents.';
                    Visible = false;
                }
                field("ValueEntry.""Expected Cost Posted to G/L"""; ValueEntry."Expected Cost Posted to G/L")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Expected Cost Posted to G/L';
                    ToolTip = 'Specifies that the expected cost is posted to interim accounts at the time of receipt.';
                    Visible = false;
                }
                field("ValueEntry.""Exp. Cost Posted to G/L (ACY)"""; ValueEntry."Exp. Cost Posted to G/L (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Exp. Cost Posted to G/L (ACY)';
                    ToolTip = 'Specifies the expense cost that was posted.';
                    Visible = false;
                }
                field("ValueEntry.""Variant Code"""; ValueEntry."Variant Code")
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Code';
                    ToolTip = 'Specifies the item variant, if any.';
                    Visible = false;
                }
                field("ValueEntry.Adjustment"; ValueEntry.Adjustment)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjustment';
                    ToolTip = 'Specifies the cost adjustment.';
                    Visible = false;
                }
                field("ValueEntry.""Capacity Ledger Entry No."""; ValueEntry."Capacity Ledger Entry No.")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Ledger Entry No.';
                    ToolTip = 'Specifies the ledger entry number.';
                    Visible = false;
                }
                field("FORMAT(ValueEntry.Type)"; Format(ValueEntry.Type))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of relation.';
                    Visible = false;
                }
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger entry where cost from the associated value entry number in this record is posted.';
                }
                field("Value Entry No."; Rec."Value Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the value entry that has its cost posted in the associated general ledger entry in this record.';
                }
                field("G/L Register No."; Rec."G/L Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger register, where the general ledger entry in this record was posted.';
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
        area(navigation)
        {
            group("Value Ent&ry")
            {
                Caption = 'Value Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ValueEntry.ShowDimensions();
                    end;
                }
                action("General Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Ledger';
                    Image = GLRegisters;
                    ToolTip = 'Open the general ledger.';

                    trigger OnAction()
                    begin
                        ValueEntry.ShowGL();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc(ValueEntry."Posting Date", ValueEntry."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not ValueEntry.Get(Rec."Value Entry No.") then
            ValueEntry.Init();
    end;

    var
        ValueEntry: Record "Value Entry";

    local procedure GetCaption(): Text[250]
    var
        GLRegister: Record "G/L Register";
    begin
        exit(StrSubstNo('%1 %2', GLRegister.TableCaption(), Rec.GetFilter("G/L Register No.")));
    end;
}

