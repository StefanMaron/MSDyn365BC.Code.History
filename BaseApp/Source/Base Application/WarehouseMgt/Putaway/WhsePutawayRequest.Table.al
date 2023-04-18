table 7324 "Whse. Put-away Request"
{
    Caption = 'Whse. Put-away Request';
    LookupPageID = "Put-away Selection";

    fields
    {
        field(1; "Document Type"; Enum "Warehouse Put-away Request Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = IF ("Document Type" = CONST(Receipt)) "Posted Whse. Receipt Header"."No."
            ELSE
            IF ("Document Type" = CONST("Internal Put-away")) "Whse. Internal Put-away Header"."No.";

            trigger OnLookup()
            var
                PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
                WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
                PostedWhseRcptList: Page "Posted Whse. Receipt List";
                WhseInternalPutAwayList: Page "Whse. Internal Put-away List";
            begin
                if "Document Type" = "Document Type"::Receipt then begin
                    if PostedWhseRcptHeader.Get("Document No.") then
                        PostedWhseRcptList.SetRecord(PostedWhseRcptHeader);
                    PostedWhseRcptList.RunModal();
                    Clear(PostedWhseRcptList);
                end else begin
                    if WhseInternalPutAwayHeader.Get("Document No.") then
                        WhseInternalPutAwayList.SetRecord(WhseInternalPutAwayHeader);
                    WhseInternalPutAwayList.RunModal();
                    Clear(WhseInternalPutAwayList);
                end;
            end;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(5; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));
        }
        field(7; "Completely Put Away"; Boolean)
        {
            Caption = 'Completely Put Away';
        }
        field(8; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

