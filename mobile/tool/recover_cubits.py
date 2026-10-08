import io, re, os

BLOC_DIR = 'lib/features/management/presentation/bloc/'

FILES = {
 'roadmap_bloc.dart': ('RoadmapBloc', 'RoadmapCubit', 'RoadmapState'),
 'property_requests_bloc.dart': ('PropertyRequestsBloc', 'PropertyRequestsCubit', 'PropertyRequestsState'),
 'finance_bloc.dart': ('FinanceBloc', 'FinanceCubit', 'FinanceState'),
 'installments_mgmt_bloc.dart': ('InstallmentsMgmtBloc', 'InstallmentsMgmtCubit', 'InstallmentsMgmtState'),
 'society_costs_bloc.dart': ('SocietyCostsBloc', 'SocietyCostsCubit', 'SocietyCostsState'),
}

for fname, (bloc, cubit, state) in FILES.items():
    p = BLOC_DIR + fname
    s = io.open(p, encoding='utf-8').read()
    # strip generated events section
    s = re.sub(
        r'// -+\n// Events\n// -+\n\nsealed class \w+Event[\s\S]*?class ' + cubit + ' extends Bloc<\\w+Event, ',
        'class ' + cubit + ' extends Cubit<' + state[:-5] + 'Event, ', s)
    s = s.replace(' extends ' + bloc[:-4] + 'Event, ' + state + '> {',
                  ' extends Cubit<' + state + '> {')
    # remove ctor handler block
    s = re.sub(r'super\((?:const )?' + state + r'\(\)\) \{[\s\S]*?\n  \}\n\n  final',
               'super(const ' + state + '());\n\n  final', s)
    # rename back
    s = s.replace(bloc, cubit)
    io.open(p.replace('_bloc.dart', '_cubit.dart'), 'w', encoding='utf-8', newline='\n').write(s)
    os.remove(p)
    print('recovered', fname, '->', os.path.basename(p).replace('_bloc.dart', '_cubit.dart'))
