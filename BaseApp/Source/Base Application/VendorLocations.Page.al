page 10013 "Vendor Locations"
{
    Caption = 'Vendor Locations';
    DataCaptionFields = "Vendor No.";
    PageType = List;
    SourceTable = "Vendor Location";

    layout
    {
        area(content)
        {
            repeater(Control1480000)
            {
                ShowCaption = false;
                field("Location Code"; "Location Code")
                {
                    ToolTip = 'Specifies the location code of the location for which this record is valid.';
                }
                field("Business Presence"; "Business Presence")
                {
                    ToolTip = 'Specifies the alternative tax area code to use when the vendor does not have a Business Presence at the location.';
                }
                field("Alt. Tax Area Code"; "Alt. Tax Area Code")
                {
                    ToolTip = 'Specifies the alternative tax area code to use when the vendor does not have a Business Presence at the location.';
                }
            }
        }
    }

    actions
    {
    }
}

