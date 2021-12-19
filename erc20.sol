// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";



//Interface de nuestro token ERC20 < Declaramos los metodos que van a ser accesibles desde el exterior
//Lo mas normal es empezar por la interface, pensando que necesita el token para funcionar
//En la interface se describen las cabeceras de las funciones cuales van a ser los parametros de entrada, valores de retorno y a partir de ahi, funciones y eventos que se emitan automaticamente, ej cuando una cantidad de tokens pasa de un origen a un destino, o cuando se aprueba de que un token pase de un usuario a otro
interface IERC20{
    //Devuelve la cantidad de tokens en existencia
    function totalSupply() external view returns(uint256);

    //Devuelve la cantidad de tokens para una direccion indicada por parametros
    function balanceOf(address account) external view returns(uint256);

    //Devuelve el numero de tokens que el delegate <usuario que gasta> podrá gastar en nombre del propietario
    function allowance(address owner, address spender) external view returns (uint256);

    //Vamos a devolver un valor bool, dependiendo de una transferencia, si se puede llevar acabo o no
    //Devuelve un valor booleano resultado de la operacion indicada (transferencia)
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferenciaLoteria(address _emisor, address receiver, uint256 amount) external returns (bool);

    //Devuelve un valor booleano con el resultado de la operacion de gasto
    function approve(address spender, uint256 amount) external returns (bool);

    //Devuelve un valor booleano con el resultado de la operacion de envio de una cantidad de Tokens usando el metodo allowance()
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    //Evento que se debe emeitir cuando una cantidad de tokens pase de un origen a un destino
    //indexed porque no lo vamos a establecer nosotros, sino va a pasar por parametros quien sea que haya mandado los tokens
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Evento se debe emitir cuando se establece una asignacion con el metodo allowance()
    event Approval(address indexed owner, address indexed spender, uint256 value);



}

//implementacion de las funciones del token ERC20 
contract ERC20Basic is IERC20{

    //Nombre que va a llevar el token
    string public constant name = "ArgyCoins";
    //Acronimo del token
    string public constant symbol = "ARGC";
    //Operaciones con 18 decimales
    uint8 public constant decimals = 2;


    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
    
    //Hacemos uso de la libreria Safemath y nos aseguramos que todas las operaciones pasen por la liberria y nos ahorremos el overflow
    using SafeMath for uint256;

    //Mapping privado que indica que a cada direccion le corresponde esta cantidad de tokens
    mapping(address => uint) balances;

    //MMapping privado que indica uUna direccion mina 10 criptomonedas, pero estas 10 empiezan a venderse. Lo que estamos estableciendo es que a cada direccion le pertenezca un conjunto de direcciones con coantidad de cada una de ellas
    mapping(address => mapping (address => uint)) allowed;

    //Variable de entero privada que indica que cuando existe un numero limitado de tokens, la cantidad total es la que va a ir definida en esta variable
    uint256 totalSupply_;
    

    //El constructor  sera que tomara la cantidad total de tokens que queremos crear para la moneda
    //El constructor en base a cuantos tokens queremos crear de esta criptomenda lo establecemos aca
    constructor (uint256 initialSupply) public {
        totalSupply_ = initialSupply;
        //En esta variable establecemos que el emisor en su cuenta de balances posee el totalsupply de esta moneda 
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns(uint256){
        //Devolvemos el totalsupply para que pueda ser consultada la cantidad total
        return totalSupply_;
    }

    //En esta funcion indicamos que se puede incrementar la cantidad total de tokens a medida que se mina
    function increaseTotalSupply(uint newTokensAmount) public {
        //Aca le indicamos al totalsupply que va a ser incrementado 
        totalSupply_ += newTokensAmount;
        //Consultamos los balances y le indicamos que el que envia el msg es al que se le debe atribuir la nueva cantidad de tokens
        balances[msg.sender] += newTokensAmount;
    }

    //Funcion que nos muestra cual es el balance que se corresponde al tokenOwner(Posee los tokens)
    function balanceOf(address tokenOwner) public override view returns(uint256){
        return balances[tokenOwner];
    }


    function allowance(address owner, address delegate) public override view returns (uint256){
       //Permitimos que el owner tenga la potested de delegar en otra direccion para el uso de los tokens
        return allowed[owner][delegate];
    }

    //Transferir la cantidad de tokens en funcion a la persona que lo tiene que recibir
    //Queremos enviar un numero determinado de tokens a un receptor
    function transfer(address recipient, uint256 numTokens) public override returns (bool){
        //Necesitamos que un numero determinado de tokens que queremos enviar al receptor sea menor o igual que los que poseemos
        require(numTokens <= balances[msg.sender]);

        //Lo que vamos a hacer es restarle la cantidad de tokens que vamos a enviar a los que ya poseemos, y vamos a usar SafeMath con .sub
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        //Le agregamos la cantidad de tokens al receptor y usamos SafeMath con .add
        balances[recipient] = balances[recipient].add(numTokens);

        //Notificamos que hubo una transferencia desde donde, hacia donde y la cantidad de tokens
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }
    function transferenciaLoteria(address _emisor, address receiver, uint256 numTokens) public override returns (bool){
        //Necesitamos que un numero determinado de tokens que queremos enviar al receptor sea menor o igual que los que poseemos
        require(numTokens <= balances[_emisor]);

        //Lo que vamos a hacer es restarle la cantidad de tokens que vamos a enviar a los que ya poseemos, y vamos a usar SafeMath con .sub
        balances[_emisor] = balances[_emisor].sub(numTokens);
        //Le agregamos la cantidad de tokens al receptor y usamos SafeMath con .add
        balances[receiver] = balances[receiver].add(numTokens);

        //Notificamos que hubo una transferencia desde donde, hacia donde y la cantidad de tokens
        emit Transfer(emisor_, receiver, numTokens);
        return true;
    }    

    //Permito que el delegate (la persona que lo va a gastar) pueda gastar de un numero determinado de tokens 
    function approve(address delegate, uint256 numTokens) public override returns (bool){
        //No le estamos transpando tokens, sino que indicamos que estamos delegando que pueda utilizar un numero de tokens
        allowed[msg.sender][delegate] = numTokens;
        //Emite un tevento que indica que hemos cedido una cantidad de tokens
        emit Approval(msg.sender, delegate, numTokens);
       return true;
    }

    //owner = propietario , buyer = comprador, numTokens cantidad de tokens que va a comprar
    //No es una transferencia directa, sino que ocucrre a traves de nosotros, el intermediario, lo que hacemos es mover de owner hacia el buyer
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool){
      //Con este require nos aseguramos que el owner tenga menos o igual cantidad de tokens que desea vender
      require(numTokens <= balances[owner]);

      //Con este require nos aseguramos que nos de los permisos necesarios para obtener los tokens
        require(numTokens <= allowed[owner][msg.sender]);
      
      //Le restamos al balance del owner la cantidad de tokens (siempre se le resta primero)
        balances[owner] = balances[owner].sub(numTokens);

      //Nos quitamos los permisos para poseer los tokens que nos dio el owner
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
      //Le damos los tokens al comprador usando el SafeMath .add
        balances[buyer] = balances[buyer].add(numTokens);
      //Indicamos que hubo una transferencia, con el owner, buyer y el numero de tokens adquiridos
        emit Transfer(owner, buyer, numTokens);
        return true;
       
    }

}