pageextension 18554 "VendorCardExt" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("State Code"; "State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the State Code of Vendor';
            }
        }
        addafter(Receiving)
        {
            group("Tax Information")
            {
                field("Assessee Code"; "Assessee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Assessee Code by whom any tax or sum of money is payable';
                }

                group("PAN Details")
                {
                    field("P.A.N. No."; "P.A.N. No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PANNoEditable;
                        ToolTip = 'Specifies the Permanent Account No. of Party';
                    }
                    field("P.A.N. Status"; "P.A.N. Status")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the PAN Status as PANAPPLIED,PANNOTAVBL,PANINVALID';

                        trigger OnValidate()
                        begin
                            PANStatusOnAfterValidate();
                        end;
                    }
                    field("P.A.N. Reference No."; "P.A.N. Reference No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the PAN Reference No. in case the PAN is not available or applied by the party';
                    }
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        PANStatusOnAfterValidate();
    end;

    trigger OnOpenPage()
    begin
        PANStatusOnAfterValidate();
    end;

    local procedure PANStatusOnAfterValidate()
    begin
        if "P.A.N. Status" <> "P.A.N. Status"::" " then
            PANNoEditable := false
        else
            PANNoEditable := true;
    end;

    var
        PANNoEditable: Boolean;
}