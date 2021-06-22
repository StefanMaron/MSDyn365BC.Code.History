page 9093 "Vendor Details FactBox"
{
    Caption = 'Vendor Details';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor No.';
                ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                Visible = ShowVendorNo;

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            field(Name; Name)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor''s name.';
            }
            field("Phone No."; "Phone No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor''s telephone number.';
            }
            field("E-Mail"; "E-Mail")
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = EMail;
                ToolTip = 'Specifies the vendor''s email address.';
            }
            field("Fax No."; "Fax No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor''s fax number.';
            }
            field(Contact; Contact)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the name of the person you regularly contact when you do business with this vendor.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Actions")
            {
                Caption = 'Actions';
                Image = "Action";
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Vendor),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        ShowVendorNo := true;
    end;

    var
        ShowVendorNo: Boolean;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Vendor Card", Rec);
    end;

    procedure SetVendorNoVisibility(Visible: Boolean)
    begin
        ShowVendorNo := Visible;
    end;
}

