page 5145 "Contact Through"
{
    Caption = 'Contact Through';
    DataCaptionFields = "Contact No.", Name;
    Editable = false;
    PageType = List;
    SourceTable = "Communication Method";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the contact to which the phone number is related. There are two options:';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the phone number or e-mail address.';
                }
                field(Number; Number)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the telephone number.';
                    Visible = NumberVisible;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = RelationshipMgmt;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the contact''s email address.';
                    Visible = EmailVisible;
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
    }

    trigger OnInit()
    begin
        EmailVisible := true;
        NumberVisible := true;
    end;

    trigger OnOpenPage()
    begin
        SetFilter(Number, '<>''''');
        if Find('-') then begin
            CurrPage.Caption := Text000;
            NumberVisible := true;
            EmailVisible := false;
        end else begin
            Reset();
            SetFilter("E-Mail", '<>''''');
            if Find('-') then begin
                CurrPage.Caption := Text001;
                NumberVisible := false;
                EmailVisible := true;
            end else
                CurrPage.Close();
        end;
    end;

    var
        Text000: Label 'Contact Phone Numbers';
        Text001: Label 'Contact Emails';
        [InDataSet]
        NumberVisible: Boolean;
        [InDataSet]
        EmailVisible: Boolean;
}

