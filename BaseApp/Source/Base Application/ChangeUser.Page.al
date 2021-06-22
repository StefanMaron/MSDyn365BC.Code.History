page 1264 "Change User"
{
    Caption = 'Change User';
    SourceTable = "Isolated Certificate";

    layout
    {
        area(content)
        {
            field("User ID"; "User ID")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User assigned to the certificate';
                LookupPageID = "User Lookup";

                trigger OnValidate()
                begin
                    TestField("User ID");
                end;
            }
        }
    }

    actions
    {
    }
}

