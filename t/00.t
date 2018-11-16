use rlib 'lib';
use DTest;
use Cwd;

diag('Running in ' . Cwd::cwd);

ok(true, "Tests run");
ok(-r -x 'ngbasm.py', 'Assembler is runnable');
ok((-r -x 'ngb') || (-r -x 'ngb.exe'), 'Compiler is runnable');

done_testing();
