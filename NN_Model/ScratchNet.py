# -*- coding: utf-8 -*-
"""
Created on Wed Feb 22 14:19:55 2017

@author: zhouyu
"""

import numpy as np
import itertools       
import matplotlib.pyplot as plt

class ScratchNet(object):
    def __init__(self,inputSize,Hidden_size,G_filter):
        # inputSize D (DXD input images)
        # hidden size is H,number of subunints
        self.params = {}
        #subunit location
        self.params['sub'] = zip(np.random.randint(0,inputSize-1,size = Hidden_size),
                              np.random.randint(0,inputSize-1,size = Hidden_size))
       # subunit diameter
        self.params['sub_r'] = 1
        self.params['D'] = inputSize
        self.params['Gfi'] = G_filter #HX1 Gaussian filter for the center
        self.params['GW'] = 1 # Gaussian filter weight
        self.params['b1'] = np.zeros(Hidden_size)
        self.params['b2'] = 0
        
    def gridInitilization(self,offset = None,*args):
        D = self.params['D'] 
        H = len(self.params['sub'])
        n = int(np.sqrt(H))
        stride = D/n+1
        if offset is None:
            offset = ()
            offset = np.random.randint(0,stride,size = (2,))
        elif offset == 'center':
             offset = [(D-(n-1)*stride)/2]*2
        else:
            offset = [x%D for x in offset]
        subx = np.arange(offset[0],D+1,stride)
        suby = np.arange(offset[1],D+1,stride)
        self.params['sub'] = [(c[0],c[1]) for c in itertools.product(subx, suby)]
        
    def loss(self,X,y=None,reg = 0.0):
        #X dimension: HXD2
        r,H,D = self.params['sub_r'],len(self.params['sub']),self.params['D']
        sub_filter = np.zeros((H,D,D))
        Gaussian_filter,GW = self.params['Gfi'],self.params['GW']
        b1,b2 = self.params['b1'],self.params['b2']
        sub_filter = self.getsubUnitFilters()
        sub_resp = np.tanh(X.dot(sub_filter.T)+b1) # tanh  = 2sig(2X)-1; #tanh' = 4(sig(2x)*(1-sig(2x)))
        resp = sub_resp.dot(Gaussian_filter)*GW+b2
        if y is None:
            return resp
        loss = np.mean((resp - y)**2)+0.5*reg*r**2 #RMSE+r^2
        grads = {}
        # grads on sub_r,sub,b1,b2,GW
        # dtanh/dx = (1+tanh)*(1-tanh)
        N = X.shape[0]
        #b = 1/np.sqrt(np.sum((resp-y)**2))d
        dresp = (1+sub_resp)*(1-sub_resp) # NXH
        #discrete variables
        xadd1 = [self.subUnits((xs+1,ys)) for xs,ys in self.params['sub']] 
        xadd1 = np.reshape(xadd1,(H,-1)) # shape HxD2
        dxadd = xadd1-sub_filter # shape HxD2
        dsubdx = ((X.dot(dxadd.T)).T).dot(np.ones((N,1))) # shape Hx1
        dsubdx = np.diag(dsubdx[:,0])
        yadd1 = [self.subUnits((xs,ys+1)) for xs,ys in self.params['sub']] 
        yadd1 = np.reshape(yadd1,(H,-1)) # shape HxD2
        dyadd = yadd1-sub_filter
        dsubdy = ((X.dot(dyadd.T)).T).dot(np.ones((N,1)))#shape Hx1
        dsubdy = np.diag(dsubdy[:,0])
        grads['dsub_filter_x'] = 2*GW*(((resp-y).T).dot(dresp)).dot(dsubdx)/N   # 1xH 
        grads['dsub_filter_y'] = 2*GW*(((resp-y).T).dot(dresp)).dot(dsubdy)/N
        # semi - numerical r gradient
        radd1 = [self.subUnits((xs,ys),self.params['sub_r']+1) for xs,ys in self.params['sub']] #HDD
        radd1 = np.reshape(radd1,(H,-1)) # HXD2
        dsubdr = np.ones((1,N)).dot(X.dot(radd1.T)-X.dot(sub_filter.T)) # 1XH
        grads['dsub_r'] = 2*GW*(((resp-y).T).dot(dresp)).dot(dsubdr.T)/N+reg*r # a number
        # continuous variables
        grads['db1'] = np.squeeze(2*GW*(dresp.T).dot(resp-y)/N)           # shape(H,)
        grads['db2'] = 2*np.sum(resp-y)/N # shape 1
        grads['dGW'] = 2*np.sum((resp-y)*(sub_resp.dot(Gaussian_filter)))/N # shape 1
        return loss,grads


    def numGradientCheck(self,X,y,reg = 0.0):
        loss,anaGrads = self.loss(X,y,reg)
        H = len(self.params['sub'])
        numerGrads = {}
        sub_x,sub_y = [np.array(k) for k in zip(*self.params['sub'])]
        sub_r = self.params['sub_r'] 
        # most cases the regularization term is canceled
        loss = loss+reg*(sub_r**2)
        b1 = self.params['b1'] 
        b2 = self.params['b2']
        Gaussian_filter,GW = self.params['Gfi'],self.params['GW']
        # precalculate the subunit filter
        sub_filter = self.getsubUnitFilters() #HXD2
        # discrete
        numerGrads['dsub_filter_x'] = np.zeros_like(anaGrads['dsub_filter_x'])
        numerGrads['dsub_filter_y']= np.zeros_like(anaGrads['dsub_filter_y'])
        numerGrads['db1']= np.zeros_like(anaGrads['db1'])
        print numerGrads['dsub_filter_x'].shape
        delta = 1
        deltac = 0.0001
        for i in xrange(H):
            # calculate the changed unit filter
            xadd = self.subUnits((sub_x[i]+delta,sub_y[i]))
            xadd = xadd.reshape(-1)
            tempX = np.copy(sub_filter)
            tempX[i,:] = xadd
            yadd = self.subUnits((sub_x[i],sub_y[i]+delta))
            yadd = yadd.reshape(-1)
            tempY = np.copy(sub_filter)
            tempY[i,:] = yadd
            badd = np.copy(b1)
            badd[i] = badd[i]+deltac
            loss_x = (np.tanh(X.dot(tempX.T)+b1)).dot(Gaussian_filter)*GW+b2
            loss_y = (np.tanh(X.dot(tempY.T)+b1)).dot(Gaussian_filter)*GW+b2
            loss_b1 = (np.tanh(X.dot(sub_filter.T)+badd)).dot(Gaussian_filter)*GW+b2
            numerGrads['dsub_filter_x'][:,i]= (np.mean((loss_x - y)**2)-loss)/delta
            numerGrads['dsub_filter_y'][:,i]= (np.mean((loss_y - y)**2)-loss)/delta
            numerGrads['db1'][i] = (np.mean((loss_b1 - y)**2)-loss)/deltac
        radd = [self.subUnits((xs,ys),sub_r+delta) for xs,ys in self.params['sub']] #HDD
        radd = np.reshape(radd,(H,-1)) # HXD2
        loss_r = (np.tanh(X.dot(radd.T)+b1)).dot(Gaussian_filter)*GW+b2
        numerGrads['dsub_r']= ((np.mean((loss_r - y)**2)-loss)+0.5*reg*(2*sub_r+1))/delta
        # continuouse variables
        loss_b2 = (np.tanh(X.dot(sub_filter.T)+b1)).dot(Gaussian_filter)*GW+b2+deltac
        numerGrads['db2']= (np.mean((loss_b2 - y)**2)-loss)/deltac
        loss_GW = (np.tanh(X.dot(sub_filter.T)+b1)).dot(Gaussian_filter)*(GW+deltac)+b2
        numerGrads['dGW']= (np.mean((loss_GW - y)**2)-loss)/deltac
        diffGrads = {}
        diffGrads['dsub_filter_x'] = np.sum(np.absolute(anaGrads['dsub_filter_x']-numerGrads['dsub_filter_x']))
        diffGrads['dsub_filter_y'] = np.sum(np.absolute(anaGrads['dsub_filter_y']-numerGrads['dsub_filter_y']))
        diffGrads['sub_r'] = np.sum(np.absolute(anaGrads['dsub_r']-numerGrads['dsub_r']))
        diffGrads['db1']= np.sum(np.absolute(anaGrads['db1']-numerGrads['db1']))
        diffGrads['db2']= np.sum(np.absolute(anaGrads['db2']-numerGrads['db2']))
        diffGrads['dGW']= np.sum(np.absolute(anaGrads['dGW']-numerGrads['dGW']))
        return diffGrads
   
    def train(self, X, y, X_val, y_val,learning_rate=1e-3, learning_rate_decay=0.95,
              reg=1e-5, num_iters=100,batch_size=200, verbose=False):
        num_train = X.shape[0]
        iterations_per_epoch = max(num_train / batch_size, 1)
        loss_history = []
        train_mse_history = []
        val_mse_history = []
        # update rule for x,y postion grating
        # rule a: only update(x,y) with unit 1 when |dx|, |dy|>1
        def dxyupdate(g):
            res = g[0]
            for i, d in enumerate(g[0]):
                if d>1:
                    res[i] = -1
                elif d<-1:
                   res[i] = 1
                else:
                   res[i] = 0
            return res.astype(int)
                 
        for it in xrange(num_iters):
            batch_ind = np.random.choice(range(num_train),batch_size,replace = True)     
            X_batch = X[batch_ind,:] 
            y_batch = y[batch_ind]
            # Compute loss and gradients using the current minibatch
            loss, grads = self.loss(X_batch, y=y_batch, reg=reg)
            loss_history.append(loss)
            # discrete parameters 'sub', 'dsub_r'
            # rule a: only update(x,y) with unit 1 when |dx|, |dy|>1
            dx = dxyupdate(grads['dsub_filter_x']*learning_rate)
            dy = dxyupdate(grads['dsub_filter_y']*learning_rate)
            x_sub,y_sub = zip(*self.params['sub'])
            self.params['sub']= zip(np.array(x_sub)+dx, np.array(y_sub)+dy)
            # rule_b: only update r with unit 1; when |dsubr|>1
            dsubr = grads['dsub_r']*learning_rate
            if dsubr > 1:
                self.params['sub_r'] = self.params['sub_r'] -1
            elif dsubr<-1:
                self.params['sub_r'] = self.params['sub_r']+1  
            # continuous parameters
            self.params['b1'] =self.params['b1']-grads['db1']*learning_rate
            self.params['GW'] =self.params['GW']-grads['dGW']*learning_rate
            self.params['b2'] =self.params['b2']-grads['db2']*learning_rate
            
            if verbose and it % 100 == 0:
                print 'iteration %d / %d: loss %f' % (it, num_iters, loss)
                # Every epoch, check train and val accuracy and decay learning rate.
            if it % iterations_per_epoch == 0:
                # Check accuracy
                train_mse = np.mean((self.predict(X)-y)**2)
                val_mse = np.mean((self.predict(X_val)-y_val)**2)
                train_mse_history.append(train_mse)
                val_mse_history.append(val_mse)
                # Decay learning rate
                learning_rate *= learning_rate_decay
        return{'loss_history':loss_history,
               'train_mse_history':train_mse_history,
               'validation_mse_history':val_mse_history,
                }
    
    def predict(self,X):
        return self.loss(X, y=None, reg=0.0)
        
    def subUnits(self,loc,*args):
        if not args:
            r = self.params['sub_r']
        else:
            r = args[0]
        sz = self.params['D']
        units = np.zeros((sz,sz))
        units[max(0,loc[0]-r):min(sz-1,loc[0]+r),max(0,loc[1]-r):min(sz-1,loc[1]+r)]=1
        return units
    
    def getsubUnitFilters(self):
        ct = 0
        H,D = len(self.params['sub']),self.params['D']
        sub_filter = np.zeros((H,D,D))
        for x0,y0 in self.params['sub']:
            sub_filter[ct,:,:] = self.subUnits((x0,y0))
            ct = ct+1
      
        sub_filter = np.reshape(sub_filter,(H,-1)) #HXD2
        return sub_filter
    
    def printSubUnitWeights(self):
        H,D = len(self.params['sub']),self.params['D']
        subUnitFilters = self.getsubUnitFilters() # H*D2
        fig, axes = plt.subplots((H+1)/2,2,figsize = (20,20))
        fig2, axes2 = plt.subplots()
        vmin, vmax = subUnitFilters.min(),subUnitFilters.max()
        for unit, ax in zip(xrange(H),axes.ravel()):
            subunit = subUnitFilters[unit,:]
            ax.matshow(subunit.reshape(D,D), cmap = plt.cm.gray, vmin = 0.5*vmin, vmax = 0.5*vmax)
            ax.set_aspect('equal')
            ax.set_xticks(())
            ax.set_yticks(())
        subunitOverlay = (subUnitFilters.sum(axis = 0)).reshape(D,D)
        axes2.matshow(subunitOverlay,cmap = plt.cm.gray, vmin = 0.5*vmin, vmax = 0.5*vmax)
        plt.show()
        
        

        
        