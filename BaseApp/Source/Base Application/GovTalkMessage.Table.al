table 10520 GovTalkMessage
{
    Caption = 'GovTalkMessage';

    fields
    {
        field(1; ReportConfigCode; Option)
        {
            Caption = 'ReportConfigCode';
            OptionCaption = 'EC Sales List,VAT Report';
            OptionMembers = "EC Sales List","VAT Report";
        }
        field(2; ReportNo; Code[20])
        {
            Caption = 'ReportNo';
        }
        field(3; PeriodID; Code[10])
        {
            Caption = 'PeriodID';
        }
        field(4; PeriodStart; Date)
        {
            Caption = 'PeriodStart';
        }
        field(5; PeriodEnd; Date)
        {
            Caption = 'PeriodEnd';
        }
        field(7; ResponseEndPoint; Text[100])
        {
            Caption = 'ResponseEndPoint';
        }
        field(8; PollInterval; Integer)
        {
            Caption = 'PollInterval';
        }
        field(10; RootXMLBuffer; Integer)
        {
            Caption = 'RootXMLBuffer';
        }
        field(11; "Polling Count"; Integer)
        {
            Caption = 'Polling Count';
        }
        field(12; "Message Class"; Text[30])
        {
            Caption = 'Message Class';
        }
    }

    keys
    {
        key(Key1; ReportConfigCode, ReportNo)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

