namespace Microsoft.Purchases.Vendor;

page 9151 "My Vendors"
{
    Caption = 'My Vendors';
    PageType = ListPart;
    SourceTable = "My Vendor";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor numbers that are displayed in the My Vendor Cue on the Role Center.';

                    trigger OnValidate()
                    begin
                        SyncFieldsWithVendor();
                    end;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phone No.';
                    DrillDown = false;
                    ExtendedDatatype = PhoneNo;
                    Lookup = false;
                    ToolTip = 'Specifies the vendor''s phone number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("<Balance>"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    ToolTip = 'Specifies the balance. ';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Vendor.OpenVendorLedgerEntries(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "Vendor Card";
                RunPageLink = "No." = field("Vendor No.");
                RunPageMode = View;
                RunPageView = sorting("No.");
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SyncFieldsWithVendor();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(Vendor)
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    var
        Vendor: Record Vendor;

    local procedure SyncFieldsWithVendor()
    var
        MyVendor: Record "My Vendor";
    begin
        Clear(Vendor);

        if Vendor.Get(Rec."Vendor No.") then
            if (Rec.Name <> Vendor.Name) or (Rec."Phone No." <> Vendor."Phone No.") then begin
                Rec.Name := Vendor.Name;
                Rec."Phone No." := Vendor."Phone No.";
                if MyVendor.Get(Rec."User ID", Rec."Vendor No.") then
                    Rec.Modify();
            end;
    end;
}

