enum 5262 "Audit File Export Format" implements "Audit File Export Data Handling", "Audit File Export Data Check"
{
    Extensible = true;

    value(0; None)
    {
        Implementation = "Audit File Export Data Handling" = "Audit File Data Handling",
                         "Audit File Export Data Check" = "Audit File Data Check";
    }
}