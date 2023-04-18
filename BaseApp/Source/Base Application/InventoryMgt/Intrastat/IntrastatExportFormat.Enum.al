#if not CLEAN22
Enum 263 "Intrastat Export Format"
{
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
    Extensible = true;

    value(0; "2021")
    {
        Caption = '2021';
    }
    value(1; "2022")
    {
        Caption = '2022';
    }
}
#endif