page 10744 "340 Declaration Lines"
{
    Caption = '340 Declaration Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "340 Declaration Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the document number on the declaration entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the document type associated with the declaration entry.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document date of the posted document.';
                }
                field("Customer/Vendor No."; "Customer/Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the customer or vendor number that is associated with the posted invoice or credit memo.';
                }
                field(Base; Base)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total invoice amount, excluding the VAT amount and EC amount on the declaration entry.';
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT percentage on the declaration entry.';
                }
                field("EC %"; "EC %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percent of Equivalence Charge (EC) on the declaration entry.';
                }
                field("VAT Amount / EC Amount"; "VAT Amount / EC Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT amount and Equivalence Charge (EC) amount.';
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT amount that is calculated from the entries, based on the same VAT percentage.';
                }
                field("EC Amount"; "EC Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the calculated Equivalence Charge (EC) amount.';
                }
                field("Amount Including VAT / EC"; "Amount Including VAT / EC")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount including VAT amount and EC amount on the declaration line.';
                }
                field("Operation Code"; "Operation Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = OperationCodeEditable;
                    ToolTip = 'Specifies the operation code for the posted document.';

                    trigger OnValidate()
                    begin
                        SetRControlsEditable;
                    end;
                }
                field("Property Location"; "Property Location")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PropertyLocationEditable;
                    ToolTip = 'Specifies the property location associated with the declaration entry.';
                }
                field("Property Tax Account No."; "Property Tax Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PropertyTaxAccountNoEditable;
                    ToolTip = 'Specifies the property tax account number for the Property Location for the operation code R.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        OperationCodeEditable := not ("Operation Code" in ['C', 'D', 'I']);
        SetRControlsEditable;
    end;

    trigger OnInit()
    begin
        OperationCodeEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        OperationCodeEditable := not ("Operation Code" in ['C', 'D', 'I']);
        SetRControlsEditable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then begin
            SetRange("Operation Code", 'R');
            SetRange("Property Location", "Property Location"::" ");
            SetRange(Type, Type::Sale);
            if not IsEmpty() then begin
                Reset;
                Error(Text001);
            end;
        end;
    end;

    var
        Text001: Label 'There are lines with empty property location for the operation code R.';
        [InDataSet]
        OperationCodeEditable: Boolean;
        [InDataSet]
        PropertyLocationEditable: Boolean;
        [InDataSet]
        PropertyTaxAccountNoEditable: Boolean;

    local procedure SetRControlsEditable()
    begin
        PropertyLocationEditable := "Operation Code" = 'R';
        PropertyTaxAccountNoEditable := "Operation Code" = 'R';
    end;
}

